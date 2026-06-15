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

        XCTAssertTrue(app.buttons["Preview"].waitForExistence(timeout: 5))
        app.buttons["Preview"].click()
        XCTAssertTrue(app.staticTexts["Preview opened."].waitForExistence(timeout: 5))

        app.typeKey("r", modifierFlags: [.command, .shift])
        XCTAssertTrue(app.staticTexts["Revealed in Finder."].waitForExistence(timeout: 5))

        app.buttons["Copy Snippet"].click()
        XCTAssertTrue(app.staticTexts["Snippet copied."].waitForExistence(timeout: 5))
        app.buttons["Copy Path"].click()
        XCTAssertTrue(app.staticTexts["Source path copied."].waitForExistence(timeout: 5))

        app.buttons["Clear search"].click()
        field.click()
        field.typeText("nomatchingphrase")
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 8))

        app.buttons["settingsButton"].click()
        XCTAssertTrue(app.windows["LocalLens Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Shortcuts: Space preview • ⌘⇧R reveal • ⌘O open • ⌥⌘C path • ⌘⇧C snippet"].waitForExistence(timeout: 5))
    }
}
