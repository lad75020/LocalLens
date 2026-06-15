import Foundation
import XCTest
@testable import LocalLens

final class OfficeMediaTypeResolverTests: XCTestCase {
    func testResolverCoversOfficeExtensions() {
        let resolver = MediaTypeResolver()
        XCTAssertEqual(resolver.mediaType(for: URL(fileURLWithPath: "deck.pptx")), .office)
        XCTAssertEqual(resolver.mediaType(for: URL(fileURLWithPath: "memo.docx")), .office)
        XCTAssertEqual(resolver.mediaType(for: URL(fileURLWithPath: "sheet.xlsx")), .office)
        XCTAssertEqual(resolver.officeKind(for: URL(fileURLWithPath: "deck.pptx")), .pptx)
        XCTAssertNotNil(resolver.contentTypeIdentifier(for: URL(fileURLWithPath: "sheet.xlsx")))
    }
}
