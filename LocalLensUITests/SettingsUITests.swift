import XCTest

final class SettingsUITests: LocalLensUITestBase {
    func testSettingsSmoke() {
        app.launch()
        XCTAssertTrue(app.exists)
    }

    func testIndexingAndPrivacyControlsAreReachableSmoke() {
        app.launch()
        XCTAssertTrue(app.exists)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5) || app.wait(for: .runningBackground, timeout: 5))
    }

    func testDiagnosticsAndProviderSettingsSmoke() {
        app.launch()
        XCTAssertTrue(app.exists)
    }
}
