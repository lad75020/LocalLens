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

    func testProfileDiscoveryParsesHermesAPIServerProfileShape() {
        let data = Data(#"{"object":"list","data":[{"id":"default","object":"profile","name":"default","is_default":true,"model":"gpt-5.5","provider":"openai-codex"}]}"#.utf8)
        let profiles = OpenAICompatibleClient.decodeHermesProfiles(from: data)

        XCTAssertEqual(profiles, [HermesProfileSummary(id: "default", displayName: "default", isDefault: true, model: "gpt-5.5", provider: "openai-codex")])
    }
}
