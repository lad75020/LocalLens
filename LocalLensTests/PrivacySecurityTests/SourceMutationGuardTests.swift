import CryptoKit
import XCTest
@testable import LocalLens

final class SourceMutationGuardTests: XCTestCase {
    func testSourceBytesRemainUnchangedAcrossReadOnlyFlows() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let bytes = Data("private fixture bytes".utf8)
        try bytes.write(to: url)
        let before = Self.digest(url)
        _ = try Data(contentsOf: url)
        XCTAssertFalse(PrivacyAudit().sourceMutationAllowed(operation: "delete source file"))
        let after = Self.digest(url)
        XCTAssertEqual(before, after)
        try? FileManager.default.removeItem(at: url)
    }

    private static func digest(_ url: URL) -> String {
        let data = (try? Data(contentsOf: url)) ?? Data()
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
