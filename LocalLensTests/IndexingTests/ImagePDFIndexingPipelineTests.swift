import Foundation
import XCTest
@testable import LocalLens

final class ImagePDFIndexingPipelineTests: XCTestCase {
    func testChunkCreationFTSInsertionEmbeddingFallbackAndCompleteCommit() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let imageURL = try MediaFixtureFactory.writePNG(text: "LocalLens pipeline text", in: root)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let cachePaths = CachePaths(root: await db.cacheRootURL)
        try cachePaths.ensureDirectories()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Fixtures", bookmarkData: Data([1]), originalPathHash: "hash", displayPath: "/redacted/Fixtures")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "screenshot-text.png", mediaType: .image)

        let result = await IndexCoordinator().indexImageOrPDF(
            asset: asset,
            sourceURL: imageURL,
            storage: storage,
            cachePaths: cachePaths,
            providers: []
        )

        XCTAssertEqual(result.state, .complete)
        XCTAssertGreaterThan(result.chunkCount, 0)
        let storedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.indexState, .complete)
        XCTAssertEqual(storedAsset?.thumbnailState, .complete)
        XCTAssertNotNil(storedAsset?.lastIndexedAt)
        let chunks = try await storage.chunks.list(assetID: asset.id)
        XCTAssertTrue(chunks.contains { $0.chunkType == .filename })
        XCTAssertTrue(chunks.allSatisfy { $0.embedding == nil && $0.embeddingModel == nil })
        let ftsResults = try await storage.chunks.searchText("screenshot", limit: 10)
        XCTAssertTrue(ftsResults.contains { $0.assetID == asset.id })
        let embeddingRecord = try await storage.extractionRecords.list(assetID: asset.id)
            .first { $0.stage == .embeddings }
        XCTAssertEqual(embeddingRecord?.status, .complete)
    }

    func testEmbeddingProviderAndPartialAssetCommitsForPDF() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let pdfURL = try MediaFixtureFactory.writePDF(pages: ["LocalLens PDF pipeline"], in: root)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let cachePaths = CachePaths(root: await db.cacheRootURL)
        try cachePaths.ensureDirectories()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "PDFs", bookmarkData: Data([2]), originalPathHash: "hash", displayPath: "/redacted/PDFs")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "document.pdf", mediaType: .pdf)
        let provider = ProviderSetting(
            id: "test-local",
            displayName: "Test Local",
            baseURL: URL(string: "http://localhost:9999/v1")!,
            isEnabled: true,
            automaticIndexingEnabled: true,
            locality: .localLoopback,
            transportState: .allowedLoopbackHTTP,
            credentialState: .noneNeeded,
            modelIDs: ["embedding-test"],
            selectedModelID: nil,
            lastHealthCheckAt: nil,
            lastHealthStatus: .healthy
        )
        let service = EmbeddingStageService()
        let result = await IndexCoordinator().indexImageOrPDF(
            asset: asset,
            sourceURL: pdfURL,
            storage: storage,
            cachePaths: cachePaths,
            embeddingStageService: service,
            providers: [provider]
        )

        XCTAssertTrue([IndexState.complete, .partial].contains(result.state))
        let storedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.indexState, result.state)
        XCTAssertEqual(storedAsset?.pageCount, 1)
        let records = try await storage.extractionRecords.list(assetID: asset.id)
        XCTAssertTrue(records.contains { $0.stage == .pdfText })
        XCTAssertTrue(records.contains { $0.stage == .embeddings })
    }

    func testCancelledCommitDoesNotMarkAssetComplete() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let imageURL = try MediaFixtureFactory.writePNG(in: root)
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = makeStorage(database: db)
        let folder = WatchedFolder(displayName: "Cancelled", bookmarkData: Data([3]), originalPathHash: "hash", displayPath: "/redacted/Cancelled")
        try await storage.watchedFolders.save(folder)
        let asset = MediaFixtureFactory.asset(folderID: folder.id, filename: "cancel.png", mediaType: .image)
        let cancellation = IndexCancellation()
        cancellation.cancel()

        let result = await IndexCoordinator().indexImageOrPDF(
            asset: asset,
            sourceURL: imageURL,
            storage: storage,
            cachePaths: CachePaths(root: await db.cacheRootURL),
            cancellation: cancellation
        )

        XCTAssertEqual(result.state, .cancelled)
        let storedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.indexState, .cancelled)
        let failures = try await storage.failures.unresolved()
        XCTAssertEqual(failures.first?.category, .cancelled)
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
