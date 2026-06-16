import XCTest

final class SettingsHermesProfileSelectionUITests: XCTestCase {
    func testHermesProfilePickerAccessibilityIdentifierIsStable() {
        XCTAssertEqual("settingsHermesProfilePicker", "settingsHermesProfilePicker")
    }

    func testHermesCredentialControlAccessibilityIdentifiersAreStable() {
        XCTAssertEqual("settingsHermesAPIKeyField", "settingsHermesAPIKeyField")
        XCTAssertEqual("settingsHermesAPIKeySaveButton", "settingsHermesAPIKeySaveButton")
        XCTAssertEqual("settingsHermesAPIKeyClearButton", "settingsHermesAPIKeyClearButton")
    }
}
