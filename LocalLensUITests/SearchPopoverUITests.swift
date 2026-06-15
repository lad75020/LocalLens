import XCTest

final class SearchPopoverUITests: LocalLensUITestBase {
    func testSearchSmoke() { app.launch(); XCTAssertTrue(app.exists) }
}
