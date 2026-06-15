import AppKit
import PDFKit
import XCTest
@testable import LocalLens

final class ThumbnailServiceTests: XCTestCase {
    func testBoundedThumbnailGenerationAcrossImagesAndPDFs() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let imageURL = try MediaFixtureFactory.writePNG(size: CGSize(width: 1600, height: 900), in: root)
        let pdfURL = try MediaFixtureFactory.writePDF(pages: ["LocalLens thumbnail PDF"], in: root)
        let cachePaths = CachePaths(root: root.appendingPathComponent("cache", isDirectory: true))
        try cachePaths.ensureDirectories()
        let service = ThumbnailService(maxDimension: 256)

        let imageID = UUID()
        let imageThumb = try await service.generateThumbnail(for: imageURL, assetID: imageID, mediaType: .image, cachePaths: cachePaths)
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageThumb.thumbnailURL.path))
        XCTAssertLessThanOrEqual(max(imageThumb.pixelWidth, imageThumb.pixelHeight), 256)
        XCTAssertTrue(imageThumb.thumbnailURL.path.hasPrefix(cachePaths.root.path))
        XCTAssertGreaterThan(imageThumb.byteCount, 0)

        let pdfID = UUID()
        let pdfThumb = try await service.generateThumbnail(for: pdfURL, assetID: pdfID, mediaType: .pdf, cachePaths: cachePaths)
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfThumb.thumbnailURL.path))
        XCTAssertLessThanOrEqual(max(pdfThumb.pixelWidth, pdfThumb.pixelHeight), 256)
        XCTAssertTrue(pdfThumb.thumbnailURL.path.hasPrefix(cachePaths.root.path))
        XCTAssertGreaterThan(pdfThumb.byteCount, 0)
    }
}
