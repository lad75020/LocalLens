import XCTest
@testable import LocalLens

final class IndexProgressStoreTests: XCTestCase {
    func testPublishesRedactedSnapshotsAndCounts() async {
        let store = IndexProgressStore()
        let updates = await store.updates()
        var iterator = updates.makeAsyncIterator()
        _ = await iterator.next()

        let indexedAt = Date(timeIntervalSince1970: 1_234)
        await store.publish(IndexProgressSnapshot(
            isRunning: true,
            isPaused: false,
            queuedCount: 3,
            runningCount: 1,
            completedCount: 9,
            failedCount: 2,
            cancelledCount: 1,
            currentSafeLabel: "/Users/laurent/Private/secret-photo.png",
            lastIndexedAt: indexedAt
        ))

        let snapshot = await iterator.next()
        XCTAssertEqual(snapshot?.queuedCount, 3)
        XCTAssertEqual(snapshot?.runningCount, 1)
        XCTAssertEqual(snapshot?.completedCount, 9)
        XCTAssertEqual(snapshot?.failedCount, 2)
        XCTAssertEqual(snapshot?.cancelledCount, 1)
        XCTAssertEqual(snapshot?.currentSafeLabel, "secret-photo.png")
        XCTAssertEqual(snapshot?.lastIndexedAt, indexedAt)

        let summary = await store.makePersistableSummary()
        XCTAssertEqual(summary["currentSafeLabel"], "secret-photo.png")
        XCTAssertFalse(summary.values.joined(separator: " ").contains("/Users/laurent/Private"))
    }
}
