import XCTest
@testable import LocalLens

final class SearchPerformanceTests: XCTestCase {
    func testSyntheticTenThousandAssetRankingStaysBounded() async throws {
        let results = (0..<10_000).map { index in
            SearchResultDTO(assetID: UUID(), filename: "asset-\(index).png", mediaType: .image, folderContext: "Fixtures", thumbnailID: nil, score: Double(10_000 - index), matchReasons: index % 2 == 0 ? [.filename] : [.visualLabel], snippet: "synthetic", pageNumber: nil, timestampStart: nil, timestampEnd: nil, isMissing: false)
        }
        let start = Date()
        let top = Array(results.sorted { $0.score > $1.score }.prefix(25))
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(top.count, 25)
        XCTAssertLessThan(elapsed, 0.5)
    }
}
