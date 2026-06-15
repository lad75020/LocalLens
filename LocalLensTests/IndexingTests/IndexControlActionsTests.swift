import XCTest
@testable import LocalLens

final class IndexControlActionsTests: XCTestCase {
    func testRetryReindexFolderIgnoreAndCancelControls() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = SearchTestSupport.storage(database: database)
        let queue = IndexQueueActor()
        let coordinator = IndexCoordinator()

        let folder = SearchTestSupport.folder()
        try await storage.watchedFolders.save(folder)
        let asset = SearchTestSupport.asset(folderID: folder.id, filename: "cancelled.mov", mediaType: .video, indexState: .failed)
        try await storage.assets.save(asset)
        let failure = IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: folder.id, stage: "videoTranscript", category: .cancelled, retryability: .retry, safeMessage: "Indexing was cancelled.", rawDebugReference: nil, createdAt: Date(), resolvedAt: nil)
        try await storage.failures.save(failure)

        try await coordinator.retryFailure(failure, storage: storage, queue: queue)
        var snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.queuedCount, 1)
        let retriedAsset = try await storage.assets.get(id: asset.id)
        XCTAssertEqual(retriedAsset?.indexState, .queued)

        try await coordinator.reindexAsset(asset.id, storage: storage, queue: queue)
        try await coordinator.reindexFolder(folder.id, storage: storage, queue: queue)
        snapshot = await queue.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.queuedCount, 3)

        let running = IndexJob(jobType: .indexAsset, assetID: asset.id, priority: 1)
        await queue.enqueue(running)
        await queue.markRunning(running.id)
        let cancellation = IndexCancellation()
        await coordinator.cancelIndexing(queue: queue, cancellation: cancellation)
        snapshot = await queue.snapshot()
        XCTAssertTrue(cancellation.isCancelled)
        XCTAssertEqual(snapshot.cancelledCount, 1)

        let ignoredFailure = IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: folder.id, stage: "ocr", category: .corruptedMedia, retryability: .ignore, safeMessage: "Corrupted media.", rawDebugReference: nil, createdAt: Date(), resolvedAt: nil)
        try await storage.failures.save(ignoredFailure)
        try await coordinator.ignoreFailure(ignoredFailure, storage: storage)
        let ignoredRecord = try await storage.failures.get(id: ignoredFailure.id)
        XCTAssertNotNil(ignoredRecord?.resolvedAt)
    }

    func testNoCancelledRecordIsMarkedComplete() async {
        let queue = IndexQueueActor()
        let job = IndexJob(jobType: .indexAsset)
        await queue.enqueue(job)
        await queue.markRunning(job.id)
        await queue.cancel(jobID: job.id)
        let jobs = await queue.allJobs()
        XCTAssertFalse(jobs.contains { $0.status == .complete && $0.id == job.id })
    }
}
