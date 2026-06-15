import XCTest

class LocalLensUITestBase: XCTestCase {
    var app: XCUIApplication!
    override func setUp() { continueAfterFailure = false; app = XCUIApplication(); app.launchArguments.append("--ui-testing") }
}
