import XCTest

@MainActor
final class OnboardingUITests: LocalLensUITestBase {
    func testFirstFolderOnboardingAddSettingsListAndRemoval() throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalLensUITestFolder-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try Data("fake image bytes".utf8).write(to: folderURL.appendingPathComponent("sample.jpg"))
        addTeardownBlock { try? FileManager.default.removeItem(at: folderURL) }

        app.launchEnvironment["LOCALLENS_UI_TEST_FOLDER"] = folderURL.path
        app.launch()

        XCTAssertTrue(app.staticTexts["Build a private media library"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add Folder…"].waitForExistence(timeout: 5))
        app.buttons["Add Folder…"].click()

        XCTAssertTrue(app.staticTexts["1 folder watched"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].click()

        XCTAssertTrue(app.staticTexts[folderURL.lastPathComponent].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Remove"].waitForExistence(timeout: 5))
        app.buttons["Remove"].click()
        let confirmationButton = app.windows["LocalLens Settings"].sheets.buttons["Remove Folder"]
        XCTAssertTrue(confirmationButton.waitForExistence(timeout: 5))
        confirmationButton.click()

        XCTAssertTrue(app.staticTexts["No watched folders yet"].waitForExistence(timeout: 8))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folderURL.appendingPathComponent("sample.jpg").path))
    }
}
