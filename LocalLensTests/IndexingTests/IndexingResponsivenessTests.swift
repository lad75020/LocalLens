import XCTest
@testable import LocalLens

final class IndexingResponsivenessTests: XCTestCase {
    func testThousandJobQueuePauseResumeCancelSnapshots() async {
        let queue = IndexQueueActor()
        for index in 0..<1_000 {
            await queue.enqueue(IndexJob(jobType: .indexAsset, priority: index % 10))
        }
        var snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.queuedCount, 1_000)
        await queue.pause()
        let pausedNext = await queue.nextJob()
        XCTAssertNil(pausedNext)
        await queue.resume()
        let next = await queue.nextJob()
        XCTAssertNotNil(next)
        if let next {
            await queue.markRunning(next.id)
            await queue.cancel(jobID: next.id)
        }
        snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.cancelledCount, 1)
        let jobs = await queue.allJobs()
        XCTAssertFalse(jobs.contains { $0.status == .complete && $0.completedAt == nil })
    }
}
