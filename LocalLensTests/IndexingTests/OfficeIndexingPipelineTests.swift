import Foundation
import XCTest
@testable import LocalLens

final class OfficeIndexingPipelineTests: XCTestCase {
    func testOfficePipelineBlocksWhenHermesProfileIsMissing() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = makeStorage(database)
        let folderID = UUID()
        let folder = WatchedFolder(id: folderID, displayName: "Office", bookmarkData: Data(), originalPathHash: "h", displayPath: "/tmp", isEnabled: true)
        let asset = MediaFixtureFactory.asset(folderID: folderID, filename: "doc.docx", mediaType: .office)
        try await storage.watchedFolders.save(folder)
        try await storage.assets.save(asset)
        let queue = IndexQueueActor()
        let job = IndexJob(jobType: .indexAsset, watchedFolderID: folderID, assetID: asset.id, priority: 1, status: .queued)
        try await storage.jobs.enqueue(job)
        await queue.enqueue(job)
        let processed = await IndexingPipelineRunner().drainQueuedJobs(storage: storage, queue: queue, progressStore: IndexProgressStore(), coordinator: IndexCoordinator(), cachePaths: CachePaths(root: database.cacheRootURL), bookmarkStore: SecurityScopedBookmarkStore(), cancellation: IndexCancellation())
        XCTAssertEqual(processed, 0)
        let failures = try await storage.failures.unresolved()
        XCTAssertEqual(failures.first?.category, .modelUnavailable)
    }

    private func makeStorage(_ database: LocalLensDatabase) -> StorageRepositories {
        StorageRepositories(watchedFolders: SQLiteWatchedFolderRepository(database: database), assets: SQLiteMediaAssetRepository(database: database), extractionRecords: SQLiteExtractionRecordRepository(database: database), chunks: SQLiteSearchableChunkRepository(database: database), jobs: SQLiteIndexJobRepository(database: database), failures: SQLiteIndexFailureRepository(database: database), providers: SQLiteProviderSettingsRepository(database: database), appSettings: SQLiteAppSettingsRepository(database: database), officePreferences: SQLiteOfficePreferencesRepository(database: database), providerModelSelections: SQLiteProviderModelSelectionRepository(database: database), hermesProfileSelection: SQLiteHermesProfileSelectionRepository(database: database), officeExtractionMetadata: SQLiteOfficeExtractionMetadataRepository(database: database), maintenance: StorageMaintenanceRepository(database: database))
    }
}
