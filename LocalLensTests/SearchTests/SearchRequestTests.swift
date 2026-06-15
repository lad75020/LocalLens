import XCTest
@testable import LocalLens

final class SearchRequestTests: XCTestCase {
    func testEmptyQueryIsRecognizedWithoutRunningProviderText() {
        let request = SearchRequest(query: "   \n\t  ")
        XCTAssertTrue(request.isEmpty)
        XCTAssertEqual(request.normalizedQuery, "")
    }

    func testLimitAndProviderQueryAreBounded() {
        let longQuery = String(repeating: "private search token ", count: 100)
        let request = SearchRequest(query: longQuery, limit: 10_000)
        XCTAssertEqual(request.limit, BuildConfiguration.maxSearchResults)
        XCTAssertLessThanOrEqual(request.boundedProviderQuery.count, BuildConfiguration.maxProviderQueryCharacters)
    }

    func testSensitiveQueryIsExcludedFromDiagnostics() {
        let sensitive = "passport secret beach photo"
        let request = SearchRequest(query: sensitive, mediaTypes: [.image], watchedFolderIDs: [UUID()], limit: 7, includeMissing: true)
        XCTAssertFalse(request.diagnosticsSummary.contains(sensitive))
        XCTAssertTrue(request.diagnosticsSummary.contains("[REDACTED]"))
        XCTAssertTrue(request.diagnosticsSummary.contains("limit: 7"))
    }
}
