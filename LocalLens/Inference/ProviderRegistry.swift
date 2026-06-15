import Foundation

public struct ProviderRegistry: Sendable {
    public let policy: ProviderTransportPolicy
    public init(policy: ProviderTransportPolicy = ProviderTransportPolicy()) { self.policy = policy }
    public func defaultProviders() -> [ProviderSetting] {
        [
            setting(id: "omlx", name: "oMLX", url: BuildConfiguration.omlxBaseURL, enabled: true, automatic: true),
            setting(id: "ollama", name: "Ollama", url: BuildConfiguration.ollamaBaseURL, enabled: true, automatic: true),
            setting(id: "hermes-agent", name: "Hermes Agent", url: BuildConfiguration.hermesAgentBaseURL, enabled: true, automatic: false),
            setting(id: "custom", name: "Custom Remote", url: URL(string: "https://example.invalid/v1")!, enabled: false, automatic: false, locality: .remote)
        ]
    }
    private func setting(id: String, name: String, url: URL, enabled: Bool, automatic: Bool, locality override: ProviderLocality? = nil) -> ProviderSetting {
        let locality = override ?? policy.locality(for: url)
        return ProviderSetting(id: id, displayName: name, baseURL: url, isEnabled: enabled, automaticIndexingEnabled: automatic, locality: locality, transportState: policy.transportState(for: url, explicitRemoteOptIn: locality == .localLoopback), credentialState: .noneNeeded, modelIDs: [], lastHealthCheckAt: nil, lastHealthStatus: .unknown)
    }
}
