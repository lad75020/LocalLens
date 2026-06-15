import AppKit
import XCTest
@testable import LocalLens

@MainActor
final class SettingsWindowPresenterTests: XCTestCase {
    func testShowCreatesRetainedSettingsWindowAndClearsOnClose() throws {
        let dependencies = try DependencyContainer()
        let presenter = SettingsWindowPresenter()

        XCTAssertNil(presenter.windowForTesting)

        presenter.show(dependencies: dependencies)
        let window = try XCTUnwrap(presenter.windowForTesting)

        XCTAssertEqual(window.title, "LocalLens Settings")
        XCTAssertFalse(window.isReleasedWhenClosed)
        XCTAssertNotNil(window.contentViewController)
        XCTAssertTrue(window.isVisible)

        presenter.close()
        XCTAssertNil(presenter.windowForTesting)
    }

    func testSettingsWindowDeclaresControlsForEverySettingsArea() {
        let requiredIDs = SettingsWindow.requiredControlAccessibilityIdentifiers

        XCTAssertTrue(requiredIDs.contains("settingsFoldersRefreshButton"))
        XCTAssertTrue(requiredIDs.contains("settingsAddFolderButton"))
        XCTAssertTrue(requiredIDs.contains("settingsIndexingRefreshButton"))
        XCTAssertTrue(requiredIDs.contains("settingsProvidersRefreshButton"))
        XCTAssertTrue(requiredIDs.contains("settingsDeleteIndexButton"))
        XCTAssertTrue(requiredIDs.contains("settingsExportDiagnosticsButton"))
        XCTAssertGreaterThanOrEqual(requiredIDs.count, 12)
    }
}
