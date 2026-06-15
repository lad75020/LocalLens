import XCTest

final class SettingsHermesProfileSelectionUITests: XCTestCase {
    func testHermesProfilePickerAccessibilityIdentifierIsStable() {
        XCTAssertEqual("settingsHermesProfilePicker", "settingsHermesProfilePicker")
    }
}
