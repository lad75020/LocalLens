import XCTest
@testable import LocalLens

final class ProviderTransportPolicyTests: XCTestCase {
    func testNormalizesLocalhostTypoAndAllowsLoopbackHTTP() throws {
        let policy = ProviderTransportPolicy()
        let url = try XCTUnwrap(policy.normalize("http://localhost://17998"))
        XCTAssertEqual(url.absoluteString, "http://localhost:17998/v1")
        XCTAssertEqual(policy.decision(for: url), .allow)
    }

    func testAllowsIPv4AndIPv6LoopbackHTTP() throws {
        let policy = ProviderTransportPolicy()
        XCTAssertEqual(policy.decision(for: URL(string: "http://127.0.0.1:11434/v1")!), .allow)
        XCTAssertEqual(policy.decision(for: URL(string: "http://[::1]:11434/v1")!), .allow)
    }

    func testBlocksPlainHTTPNonLoopbackAndRequiresRemoteHTTPSOptIn() throws {
        let policy = ProviderTransportPolicy()
        XCTAssertEqual(policy.decision(for: URL(string: "http://example.com/v1")!), .blockPlainHTTPNonLoopback)
        XCTAssertEqual(policy.decision(for: URL(string: "https://example.com/v1")!), .requireExplicitRemoteOptIn)
        XCTAssertEqual(policy.decision(for: URL(string: "https://example.com/v1")!, explicitRemoteOptIn: true), .allow)
    }

    func testProviderRegistryDefaultsKeepHermesOutOfBulkIndexing() {
        let providers = ProviderRegistry().defaultProviders()
        XCTAssertEqual(providers.first { $0.id == "omlx" }?.automaticIndexingEnabled, true)
        XCTAssertEqual(providers.first { $0.id == "ollama" }?.automaticIndexingEnabled, true)
        XCTAssertEqual(providers.first { $0.id == "hermes-agent" }?.automaticIndexingEnabled, false)
        XCTAssertEqual(providers.first { $0.id == "custom" }?.isEnabled, true)
        XCTAssertEqual(providers.first { $0.id == "custom" }?.automaticIndexingEnabled, false)
        XCTAssertEqual(providers.first { $0.id == "custom" }?.locality, .remote)
    }

    func testKeychainSecretPersistenceRoundTrip() throws {
        let store = ProviderCredentialStore()
        let providerID = "unit-test-\(UUID().uuidString)"
        defer { try? store.delete(providerID: providerID) }
        try store.save(apiKey: "sk-secret-value", providerID: providerID)
        XCTAssertEqual(try store.read(providerID: providerID), "sk-secret-value")
        try store.delete(providerID: providerID)
        XCTAssertNil(try store.read(providerID: providerID))
    }
}
