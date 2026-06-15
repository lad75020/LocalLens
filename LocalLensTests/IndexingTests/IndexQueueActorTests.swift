import XCTest
@testable import LocalLens

final class IndexQueueActorTests: XCTestCase {
    func testPauseResumeCancelRetryStateTransitions() async {
        let queue = IndexQueueActor()
        let job = IndexJob(jobType: .indexAsset, priority: 10)
        await queue.enqueue(job)
        let firstJob = await queue.nextJob()
        XCTAssertEqual(firstJob?.id, job.id)
        await queue.pause()
        let pausedJob = await queue.nextJob()
        XCTAssertNil(pausedJob)
        await queue.resume()
        await queue.markRunning(job.id)
        var snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.runningCount, 1)
        await queue.cancel(jobID: job.id)
        snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.cancelledCount, 1)
        await queue.retry(jobID: job.id)
        snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.queuedCount, 1)
    }
}
