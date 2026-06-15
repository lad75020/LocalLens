import CryptoKit
import Foundation
import XCTest
@testable import LocalLens

final class OfficeSourceMutationGuardTests: XCTestCase {
    func testDiscoveryPromptAndRejectedRoutingDoNotMutateSourceBytes() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = root.appendingPathComponent("source.docx")
        try Data("source office bytes".utf8).write(to: url)
        let before = try digest(url)
        _ = try MediaDiscoveryService().discover(in: root, watchedFolderID: UUID(), officePolicy: OfficeDiscoveryPolicy(pptxEnabled: true, docxEnabled: true, xlsxEnabled: true, hermesReadyForOfficeIndexing: true))
        _ = PromptTemplates.officePrompt(kind: .docx, filename: url.lastPathComponent, documentTextOrReference: "source office bytes")
        let after = try digest(url)
        XCTAssertEqual(before, after)
    }

    private func digest(_ url: URL) throws -> String {
        SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
    }
}
