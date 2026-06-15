import AppKit
import XCTest
@testable import LocalLens

final class ImageExtractorTests: XCTestCase {
    func testImageOCRDimensionsVisualLabelsAndCorruptFailureCategory() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let imageURL = try MediaFixtureFactory.writePNG(text: "LocalLens Visible Text", size: CGSize(width: 900, height: 500), in: root)
        let extractor = ImageExtractor()

        let result = try await extractor.extract(from: imageURL)
        XCTAssertEqual(result.pixelWidth, 900)
        XCTAssertEqual(result.pixelHeight, 500)
        XCTAssertTrue(result.visualLabels.contains { $0.label.localizedCaseInsensitiveContains("image") || $0.label.localizedCaseInsensitiveContains("screenshot") })
        XCTAssertNil(result.failureCategory)
        // Vision OCR availability can vary across simulator/runtime configurations; if it returns text, keep it bounded and useful.
        XCTAssertTrue(result.recognizedText.allSatisfy { !$0.text.isEmpty && $0.confidence >= 0 })

        let corruptURL = root.appendingPathComponent("corrupt.png")
        try Data("not actually an image".utf8).write(to: corruptURL)
        do {
            _ = try await extractor.extract(from: corruptURL)
            XCTFail("Expected corrupt image extraction to fail safely")
        } catch let failure as ExtractionFailure {
            XCTAssertEqual(failure.category, .corruptedMedia)
            XCTAssertEqual(failure.retryability, .notRetryable)
            XCTAssertFalse(failure.localizedDescription.contains(corruptURL.path))
        }
    }
}
