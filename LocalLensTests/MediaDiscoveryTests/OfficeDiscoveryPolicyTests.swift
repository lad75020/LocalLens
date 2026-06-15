import Foundation
import XCTest
@testable import LocalLens

final class OfficeDiscoveryPolicyTests: XCTestCase {
    func testOfficeFilesAreSkippedWhenTogglesOrHermesReadinessAreDisabled() throws {
        let root = try MediaFixtureFactory.tempRoot()
        try Data("deck".utf8).write(to: root.appendingPathComponent("deck.pptx"))
        let disabled = try MediaDiscoveryService().discover(in: root, watchedFolderID: UUID())
        XCTAssertEqual(disabled.assets.count, 0)
        let notReady = try MediaDiscoveryService().discover(in: root, watchedFolderID: UUID(), officePolicy: OfficeDiscoveryPolicy(pptxEnabled: true, docxEnabled: true, xlsxEnabled: true, hermesReadyForOfficeIndexing: false))
        XCTAssertEqual(notReady.assets.count, 0)
    }

    func testOfficeFilesQueueWhenToggleAndHermesReadinessAllow() throws {
        let root = try MediaFixtureFactory.tempRoot()
        try Data("deck".utf8).write(to: root.appendingPathComponent("deck.pptx"))
        try Data("doc".utf8).write(to: root.appendingPathComponent("doc.docx"))
        let result = try MediaDiscoveryService().discover(in: root, watchedFolderID: UUID(), officePolicy: OfficeDiscoveryPolicy(pptxEnabled: true, docxEnabled: false, xlsxEnabled: false, hermesReadyForOfficeIndexing: true))
        XCTAssertEqual(result.assets.map(\.filename), ["deck.pptx"])
        XCTAssertEqual(result.jobs.filter { $0.jobType == .indexAsset }.count, 1)
    }
}
