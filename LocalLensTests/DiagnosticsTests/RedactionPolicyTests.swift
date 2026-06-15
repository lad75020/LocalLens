import XCTest
@testable import LocalLens

final class RedactionPolicyTests: XCTestCase {
    func testRedactsSensitiveDiagnostics() {
        let policy = RedactionPolicy()
        XCTAssertFalse(policy.redactPath("/Users/laurent/private/photo.png").contains("photo.png"))
        XCTAssertEqual(policy.redactCredential("secret"), "<redacted credential>")
        XCTAssertEqual(policy.redactExtractedContent("private transcript"), "<omitted private media content>")
    }
}
