import Foundation
import XCTest
@testable import LocalLens

final class SecurityScopedBookmarkStoreTests: XCTestCase {
    func testSaveRestoreAndBalancedStartStop() throws {
        let folder = URL(fileURLWithPath: "/tmp/LocalLensFixtures")
        final class Counter: @unchecked Sendable { var starts = 0; var stops = 0 }
        let counter = Counter()
        let store = SecurityScopedBookmarkStore(
            createBookmarkData: { Data($0.path.utf8) },
            resolveBookmarkData: { data in
                SecurityScopedBookmarkResolution(url: URL(fileURLWithPath: String(decoding: data, as: UTF8.self)), isStale: false)
            },
            startAccessing: { _ in counter.starts += 1; return true },
            stopAccessing: { _ in counter.stops += 1 }
        )

        let bookmark = try store.makeBookmark(for: folder)
        let resolution = try store.resolve(bookmark)
        XCTAssertEqual(resolution.url.path, folder.path)
        XCTAssertFalse(resolution.isStale)

        let token = try store.accessToken(for: bookmark)
        XCTAssertEqual(counter.starts, 1)
        token.stop()
        token.stop()
        XCTAssertEqual(counter.stops, 1)
    }

    func testStaleBookmarkAndDeniedAccessAreReported() throws {
        let staleStore = SecurityScopedBookmarkStore(
            createBookmarkData: { _ in Data("stale".utf8) },
            resolveBookmarkData: { _ in SecurityScopedBookmarkResolution(url: URL(fileURLWithPath: "/tmp/stale"), isStale: true) },
            startAccessing: { _ in true },
            stopAccessing: { _ in }
        )
        XCTAssertThrowsError(try staleStore.accessToken(for: Data("stale".utf8))) { error in
            XCTAssertEqual(error as? SecurityScopedBookmarkError, .staleBookmark("/tmp/stale"))
        }

        let deniedStore = SecurityScopedBookmarkStore(
            createBookmarkData: { _ in Data("denied".utf8) },
            resolveBookmarkData: { _ in SecurityScopedBookmarkResolution(url: URL(fileURLWithPath: "/tmp/denied"), isStale: false) },
            startAccessing: { _ in false },
            stopAccessing: { _ in }
        )
        XCTAssertThrowsError(try deniedStore.accessToken(for: Data("denied".utf8))) { error in
            XCTAssertEqual(error as? SecurityScopedBookmarkError, .accessDenied("/tmp/denied"))
        }
    }
}
