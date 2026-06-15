import Foundation
import XCTest
@testable import LocalLens

final class HermesProfileDiscoveryTests: XCTestCase {
    func testProfileDiscoveryParsesAlternateDisplayNameFields() {
        let data = Data(#"{"data":[{"id":"default","display_name":"Default","is_default":true},{"id":"office","friendly_name":"Office"}]}"#.utf8)
        let profiles = OpenAICompatibleClient.decodeHermesProfiles(from: data)
        XCTAssertEqual(profiles.map(\.displayName), ["Default", "Office"])
        XCTAssertTrue(profiles[0].isDefault)
    }
}
