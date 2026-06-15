import XCTest
@testable import LocalLens

final class ProviderPrivacyDefaultsTests: XCTestCase {
    func testDefaultProvidersArePrivateAndRemoteGuarded() {
        let providers = ProviderRegistry().defaultProviders()
        let audit = PrivacyAudit()
        XCTAssertTrue(audit.providerDefaultsArePrivate(providers))
        XCTAssertEqual(providers.first(where: { $0.id == "hermes-agent" })?.automaticIndexingEnabled, false)
        XCTAssertEqual(providers.first(where: { $0.id == "custom" })?.isEnabled, false)
        XCTAssertFalse(audit.remoteTransmissionAllowed(url: URL(string: "https://api.example.com/v1")!, optedIn: false))
        XCTAssertTrue(audit.remoteTransmissionAllowed(url: URL(string: "https://api.example.com/v1")!, optedIn: true))
        XCTAssertFalse(audit.remoteTransmissionAllowed(url: URL(string: "http://api.example.com/v1")!, optedIn: true))
    }
}
