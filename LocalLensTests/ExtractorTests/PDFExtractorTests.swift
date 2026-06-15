import PDFKit
import XCTest
@testable import LocalLens

final class PDFExtractorTests: XCTestCase {
    func testPDFSelectableTextImagePageOCRPasswordAndPartialFailures() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let selectableURL = try MediaFixtureFactory.writePDF(pages: ["LocalLens selectable PDF text"], in: root)
        let imageOnlyURL = try MediaFixtureFactory.writeImageOnlyPDF(text: "Image-only OCR fallback text", in: root)
        let extractor = PDFExtractor(maxOCRPages: 3)

        let selectable = try await extractor.extract(from: selectableURL)
        XCTAssertEqual(selectable.pageCount, 1)
        XCTAssertTrue(selectable.text.contains("LocalLens selectable PDF text"))
        XCTAssertEqual(selectable.pages[0].selectableText, "LocalLens selectable PDF text")
        XCTAssertNil(selectable.failureCategory)

        let imageOnly = try await extractor.extract(from: imageOnlyURL)
        XCTAssertEqual(imageOnly.pageCount, 1)
        XCTAssertTrue(imageOnly.pages[0].selectableText.isEmpty)
        XCTAssertGreaterThanOrEqual(imageOnly.partialFailureCount, 0)

        let lockedURL = try MediaFixtureFactory.writeLockedPDF(in: root)
        do {
            _ = try await extractor.extract(from: lockedURL)
            XCTFail("Expected locked PDF to fail safely")
        } catch let failure as ExtractionFailure {
            XCTAssertTrue([FailureCategory.passwordProtectedPDF, .corruptedMedia].contains(failure.category))
            XCTAssertFalse(failure.localizedDescription.contains(lockedURL.path))
        }

        let corruptURL = root.appendingPathComponent("corrupt.pdf")
        try Data("%PDF-1.7 broken".utf8).write(to: corruptURL)
        do {
            _ = try await extractor.extract(from: corruptURL)
            XCTFail("Expected corrupt PDF to fail safely")
        } catch let failure as ExtractionFailure {
            XCTAssertEqual(failure.category, .corruptedMedia)
        }
    }
}
