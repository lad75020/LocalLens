import XCTest

final class SettingsOfficeIndexingUITests: XCTestCase {
    func testOfficeSettingsAccessibilityIdentifiersAreDocumented() {
        XCTAssertEqual("settingsOfficePPTXToggle", "settingsOfficePPTXToggle")
        XCTAssertEqual("settingsOfficeDOCXToggle", "settingsOfficeDOCXToggle")
        XCTAssertEqual("settingsOfficeXLSXToggle", "settingsOfficeXLSXToggle")
    }
}
