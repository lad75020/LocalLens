import Foundation
import XCTest
@testable import LocalLens

final class AudioVideoIndexingPipelineTests: XCTestCase {
    func testAudioPipelinePartialStateTimestampedChunksAndNoSourceMutation() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let audioURL = try MediaFixtureFactory.writeWAV(named: "meeting.wav", durationSeconds: 1.0, in: root)
        let before = try fileSnapshot(audioURL)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Audio", bookmarkData: Data([4]), originalPathHash: "hash", displayPath: "/redacted/Audio")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "meeting.wav", mediaType: .audio)
        let extractor = AudioTranscriptExtractor(transcriptProvider: nil)

        let result = await IndexCoordinator().indexAudioVideo(
            asset: asset,
            sourceURL: audioURL,
            storage: storage,
            audioExtractor: extractor
        )

        XCTAssertEqual(result.state, .partial)
        XCTAssertEqual(result.failureCategory, .modelUnavailable)
        let storedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.indexState, .partial)
        XCTAssertGreaterThan(storedAsset?.durationSeconds ?? 0, 0)
        let records = try await storage.extractionRecords.list(assetID: asset.id)
        XCTAssertTrue(records.contains { $0.stage == .audioTranscript && $0.status == .partial && $0.errorCategory == .modelUnavailable })
        let chunks = try await storage.chunks.list(assetID: asset.id)
        XCTAssertTrue(chunks.contains { $0.chunkType == .filename })
        XCTAssertEqual(try fileSnapshot(audioURL), before)
    }

    func testAudioPipelineStoresTimestampedTranscriptAndFTS() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let audioURL = try MediaFixtureFactory.writeWAV(named: "interview.wav", durationSeconds: 1.0, in: root)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Audio", bookmarkData: Data([5]), originalPathHash: "hash", displayPath: "/redacted/Audio")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "interview.wav", mediaType: .audio)
        let extractor = AudioTranscriptExtractor(transcriptProvider: StubTranscriptProvider(segments: [
            TranscriptSegment(text: "private spoken transcript", timestampStart: 0.2, timestampEnd: 0.7, confidence: 0.9)
        ]))

        let result = await IndexCoordinator().indexAudioVideo(asset: asset, sourceURL: audioURL, storage: storage, audioExtractor: extractor)

        XCTAssertEqual(result.state, .complete)
        let chunks = try await storage.chunks.list(assetID: asset.id)
        let transcriptChunk = try XCTUnwrap(chunks.first { $0.chunkType == .transcript })
        XCTAssertEqual(try XCTUnwrap(transcriptChunk.timestampStart), 0.2, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(transcriptChunk.timestampEnd), 0.7, accuracy: 0.01)
        let fts = try await storage.chunks.searchText("spoken", limit: 10)
        XCTAssertTrue(fts.contains { $0.assetID == asset.id })
    }

    func testVideoPipelineStoresSceneMetadataTranscriptAndSamplingBounds() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let videoURL = try await MediaFixtureFactory.writeVideo(named: "scene.mov", durationSeconds: 2.0, frameCount: 4, in: root)
        let before = try fileSnapshot(videoURL)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Video", bookmarkData: Data([6]), originalPathHash: "hash", displayPath: "/redacted/Video")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "scene.mov", mediaType: .video)
        let extractor = VideoSceneExtractor(
            maxSampledFrames: 2,
            transcriptProvider: StubTranscriptProvider(segments: [TranscriptSegment(text: "camera audio words", timestampStart: 0.1, timestampEnd: 0.9)]),
            frameAnalyzer: StubFrameAnalyzer()
        )

        let result = await IndexCoordinator().indexAudioVideo(asset: asset, sourceURL: videoURL, storage: storage, videoExtractor: extractor)

        XCTAssertEqual(result.state, .complete)
        XCTAssertLessThanOrEqual(result.sampledFrameCount, 2)
        let storedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.thumbnailState, .complete)
        XCTAssertGreaterThan(storedAsset?.durationSeconds ?? 0, 0)
        let records = try await storage.extractionRecords.list(assetID: asset.id)
        XCTAssertTrue(records.contains { $0.stage == .videoKeyframe })
        XCTAssertTrue(records.contains { $0.stage == .sceneLabels })
        XCTAssertTrue(records.contains { $0.stage == .videoTranscript })
        let chunks = try await storage.chunks.list(assetID: asset.id)
        XCTAssertTrue(chunks.contains { $0.chunkType == .visualLabel && $0.timestampStart != nil })
        XCTAssertTrue(chunks.contains { $0.chunkType == .transcript && $0.timestampStart != nil })
        XCTAssertEqual(try fileSnapshot(videoURL), before)
    }

    func testProviderTimeoutCreatesPartialAudioRecord() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let audioURL = try MediaFixtureFactory.writeWAV(named: "timeout.wav", durationSeconds: 1.0, in: root)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Audio", bookmarkData: Data([7]), originalPathHash: "hash", displayPath: "/redacted/Audio")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "timeout.wav", mediaType: .audio)
        let extractor = AudioTranscriptExtractor(
            transcriptProvider: StubTranscriptProvider(segments: [], mode: .sleep),
            providerTimeoutSeconds: 0.05
        )

        let result = await IndexCoordinator().indexAudioVideo(asset: asset, sourceURL: audioURL, storage: storage, audioExtractor: extractor)

        XCTAssertEqual(result.state, .partial)
        XCTAssertEqual(result.failureCategory, .providerTimeout)
        let records = try await storage.extractionRecords.list(assetID: asset.id)
        XCTAssertTrue(records.contains { $0.stage == .audioTranscript && $0.errorCategory == .providerTimeout })
    }

    private func fileSnapshot(_ url: URL) throws -> FileSnapshot {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        return FileSnapshot(
            size: attrs[.size] as? Int64 ?? 0,
            modified: attrs[.modificationDate] as? Date
        )
    }

    private func makeStorage(database: LocalLensDatabase) -> StorageRepositories {
        StorageRepositories(
            watchedFolders: SQLiteWatchedFolderRepository(database: database),
            assets: SQLiteMediaAssetRepository(database: database),
            extractionRecords: SQLiteExtractionRecordRepository(database: database),
            chunks: SQLiteSearchableChunkRepository(database: database),
            jobs: SQLiteIndexJobRepository(database: database),
            failures: SQLiteIndexFailureRepository(database: database),
            providers: SQLiteProviderSettingsRepository(database: database),
            appSettings: SQLiteAppSettingsRepository(database: database),
            officePreferences: SQLiteOfficePreferencesRepository(database: database),
            providerModelSelections: SQLiteProviderModelSelectionRepository(database: database),
            hermesProfileSelection: SQLiteHermesProfileSelectionRepository(database: database),
            officeExtractionMetadata: SQLiteOfficeExtractionMetadataRepository(database: database),
            maintenance: StorageMaintenanceRepository(database: database)
        )
    }
}

private struct FileSnapshot: Equatable {
    let size: Int64
    let modified: Date?
}
