import XCTest

final class SettingsUITests: LocalLensUITestBase {
    func testSettingsSmoke() { app.launch(); XCTAssertTrue(app.exists) }
}
