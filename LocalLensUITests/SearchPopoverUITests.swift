import XCTest

@MainActor
final class SearchPopoverUITests: LocalLensUITestBase {
    func testMenuBarSearchKeyboardNavigationEmptyStateAndMatchReasons() throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalLensSearchUITest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try Data("fake local image bytes".utf8).write(to: folderURL.appendingPathComponent("sunset-beach.jpg"))
        addTeardownBlock { try? FileManager.default.removeItem(at: folderURL) }

        app.launchEnvironment["LOCALLENS_UI_TEST_FOLDER"] = folderURL.path
        app.launch()

        XCTAssertTrue(app.buttons["Add Folder…"].waitForExistence(timeout: 5))
        app.buttons["Add Folder…"].click()
        XCTAssertTrue(app.staticTexts["1 folder watched"].waitForExistence(timeout: 8))

        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.click()
        field.typeText("sunset")

        XCTAssertTrue(app.staticTexts["sunset-beach.jpg"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Filename"].waitForExistence(timeout: 5))

        app.typeKey(.downArrow, modifierFlags: [])
        XCTAssertTrue(app.otherElements["searchResultsList"].exists || app.scrollViews["searchResultsList"].exists)

        app.buttons["Clear search"].click()
        field.click()
        field.typeText("nomatchingphrase")
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 8))
    }
}
