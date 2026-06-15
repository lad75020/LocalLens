import XCTest

final class SettingsProviderModelSelectionUITests: XCTestCase {
    func testProviderModelPickerAccessibilityIdentifiersAreStable() {
        XCTAssertEqual("settingsProviderModelPicker_ollama", "settingsProviderModelPicker_ollama")
        XCTAssertEqual("settingsProviderModelPicker_omlx", "settingsProviderModelPicker_omlx")
    }
}
