import XCTest

@MainActor
class LocalLensUITestBase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--ui-testing-fresh-state")
        app.launchArguments.append("--ui-testing-window")
    }
}
