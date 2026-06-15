import Foundation
import XCTest
@testable import LocalLens

final class IndexingPipelineRunnerTests: XCTestCase {
    func testFolderSelectionQueueStartsAndIndexesWhenAutomaticProviderEnabled() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        _ = try MediaFixtureFactory.writePNG(text: "LocalLens automatic indexing", in: root)
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = SearchTestSupport.storage(database: database)
        let cachePaths = CachePaths(root: await database.cacheRootURL)
        try cachePaths.ensureDirectories()
        let queue = IndexQueueActor()
        let progressStore = IndexProgressStore()
        let runner = IndexingPipelineRunner()

        let folder = WatchedFolder(
            displayName: "Selected Folder",
            bookmarkData: Data(root.path.utf8),
            originalPathHash: "hash",
            displayPath: root.path
        )
        try await storage.watchedFolders.save(folder)

        let discovery = try MediaDiscoveryService().discover(in: root, watchedFolderID: folder.id)
        XCTAssertGreaterThan(discovery.assets.count, 0)
        for asset in discovery.assets {
            try await storage.assets.save(asset)
        }
        for job in discovery.jobs {
            try await storage.jobs.enqueue(job)
            await queue.enqueue(job)
        }

        let provider = ProviderSetting(
            id: "test-local-provider",
            displayName: "Test Local Provider",
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
        try await storage.providers.save(provider)

        let bookmarkStore = SecurityScopedBookmarkStore(
            createBookmarkData: { url in Data(url.path.utf8) },
            resolveBookmarkData: { data in
                let path = String(decoding: data, as: UTF8.self)
                return SecurityScopedBookmarkResolution(url: URL(fileURLWithPath: path, isDirectory: true), isStale: false)
            },
            startAccessing: { _ in true },
            stopAccessing: { _ in }
        )

        let initialSnapshot = await queue.snapshot()
        XCTAssertGreaterThan(initialSnapshot.queuedCount, 0)

        let processedCount = await runner.drainQueuedJobs(
            storage: storage,
            queue: queue,
            progressStore: progressStore,
            coordinator: IndexCoordinator(),
            cachePaths: cachePaths,
            bookmarkStore: bookmarkStore,
            cancellation: IndexCancellation()
        )

        XCTAssertGreaterThan(processedCount, 0)
        let finalSnapshot = await queue.snapshot()
        XCTAssertEqual(finalSnapshot.queuedCount, 0)
        XCTAssertGreaterThan(finalSnapshot.completedCount, 0)

        let assets = try await storage.assets.list(watchedFolderID: folder.id)
        XCTAssertTrue(assets.contains { asset in
            [.complete, .partial].contains(asset.indexState) && asset.lastIndexedAt != nil
        })
        let chunks = try await storage.chunks.list(assetID: try XCTUnwrap(assets.first?.id))
        XCTAssertFalse(chunks.isEmpty)
    }
}
