import XCTest
@testable import LocalLens

final class LocalLensDatabaseTests: XCTestCase {
    func testMigrationCreatesCoreTablesAndFTS() async throws {
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let migrationCount = try await db.scalarInt("SELECT COUNT(*) AS count FROM schema_migrations WHERE version = 1;")
        let tableCount = try await db.scalarInt("SELECT COUNT(*) AS count FROM sqlite_master WHERE name IN ('watched_folders','media_assets','searchable_chunks_fts','provider_settings','app_settings');")
        XCTAssertEqual(migrationCount, 1)
        XCTAssertGreaterThanOrEqual(tableCount, 5)
    }

    func testCachePathCreationUsesAppPrivateDirectories() async throws {
        let db = try TestDependencyFactory.temporaryDatabase()
        let cacheRootURL = await db.cacheRootURL
        let paths = CachePaths(root: cacheRootURL)
        try paths.ensureDirectories()
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.temporary().deletingLastPathComponent().path))
    }

    func testSQLiteRepositoriesPersistCoreDomainRecords() async throws {
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let watchedFolders = SQLiteWatchedFolderRepository(database: db)
        let assets = SQLiteMediaAssetRepository(database: db)
        let extractionRecords = SQLiteExtractionRecordRepository(database: db)
        let chunks = SQLiteSearchableChunkRepository(database: db)
        let jobs = SQLiteIndexJobRepository(database: db)
        let failures = SQLiteIndexFailureRepository(database: db)
        let providers = SQLiteProviderSettingsRepository(database: db)
        let appSettings = SQLiteAppSettingsRepository(database: db)
        let maintenance = StorageMaintenanceRepository(database: db)

        let folder = WatchedFolder(displayName: "Fixture", bookmarkData: Data([1, 2, 3]), originalPathHash: "hash", displayPath: "/redacted/Fixture")
        try await watchedFolders.save(folder)
        let storedFolder = try await watchedFolders.get(id: folder.id)
        XCTAssertEqual(storedFolder?.displayName, "Fixture")

        let asset = MediaAsset(
            id: UUID(),
            watchedFolderID: folder.id,
            fileIdentity: "identity",
            pathRelativeToFolder: "image.png",
            pathHash: "assetHash",
            filename: "image.png",
            mediaType: .image,
            contentType: "public.png",
            sizeBytes: 42,
            createdAtFile: nil,
            modifiedAtFile: Date(timeIntervalSince1970: 20),
            indexedFileSignature: "sig",
            dimensions: "10x10",
            durationSeconds: nil,
            pageCount: nil,
            thumbnailState: .complete,
            indexState: .queued,
            lastIndexedAt: nil,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        try await assets.save(asset)
        try await assets.updateIndexState(id: asset.id, state: .complete, lastIndexedAt: Date(timeIntervalSince1970: 30))
        let storedAsset = try await assets.get(id: asset.id)
        XCTAssertEqual(storedAsset?.indexState, .complete)

        let record = ExtractionRecord(id: UUID(), assetID: asset.id, stage: .imageOCR, providerID: "AppleVision", providerMode: .localFramework, status: .complete, outputSummary: "text extracted", confidence: 0.9, pageNumber: nil, timestampStart: nil, timestampEnd: nil, errorCategory: nil, createdAt: Date(), updatedAt: Date())
        try await extractionRecords.save(record)
        let storedRecords = try await extractionRecords.list(assetID: asset.id)
        let storedStages = storedRecords.map { $0.stage }
        XCTAssertEqual(storedStages, [ExtractionStage.imageOCR])

        let chunk = SearchableChunk(id: UUID(), assetID: asset.id, extractionRecordID: record.id, chunkType: .visibleText, text: "visible menu text", normalizedText: "visible menu text", embedding: [1, 0], embeddingModel: "test-embedding", pageNumber: nil, timestampStart: nil, timestampEnd: nil, confidence: 0.8, createdAt: Date())
        try await chunks.save(chunk)
        let storedChunks = try await chunks.list(assetID: asset.id)
        XCTAssertEqual(storedChunks.count, 1)
        let searchResults = try await chunks.searchText("visible", limit: 10)
        XCTAssertEqual(searchResults.count, 1)

        let job = IndexJob(jobType: .indexAsset, watchedFolderID: folder.id, assetID: asset.id, priority: 5)
        try await jobs.enqueue(job)
        let nextJob = try await jobs.nextRunnableJob()
        XCTAssertEqual(nextJob?.id, job.id)

        let failure = IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: folder.id, stage: "imageOCR", category: .corruptedMedia, retryability: .notRetryable, safeMessage: "Cannot read image", rawDebugReference: nil, createdAt: Date(), resolvedAt: nil)
        try await failures.save(failure)
        let unresolvedFailures = try await failures.unresolved()
        XCTAssertEqual(unresolvedFailures.count, 1)
        try await failures.resolve(id: failure.id, at: Date())
        let failuresAfterResolve = try await failures.unresolved()
        XCTAssertEqual(failuresAfterResolve.count, 0)

        var provider = ProviderRegistry().defaultProviders()[0]
        provider.modelIDs = ["embedding-model"]
        provider.lastHealthStatus = .healthy
        try await providers.save(provider)
        let storedProvider = try await providers.get(id: provider.id)
        XCTAssertEqual(storedProvider?.modelIDs, ["embedding-model"])

        try await appSettings.set("true", forKey: "hasCompletedOnboarding")
        let onboarding = try await appSettings.value(forKey: "hasCompletedOnboarding")
        XCTAssertEqual(onboarding, "true")

        let assetCount = try await maintenance.indexedAssetCount()
        XCTAssertEqual(assetCount, 1)
        try await maintenance.deleteIndexData()
        let deletedAssetCount = try await maintenance.indexedAssetCount()
        XCTAssertEqual(deletedAssetCount, 0)
    }
}
