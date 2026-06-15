import XCTest

final class OnboardingUITests: LocalLensUITestBase {
    func testAppLaunches() { app.launch(); XCTAssertTrue(app.exists) }
}
