import Foundation

public struct PrivacyAuditReport: Equatable, Sendable {
    public var remoteTransmissionBlockedByDefault: Bool
    public var sourceMutationBlocked: Bool
    public var providerDefaultsPrivate: Bool
    public var diagnosticsRedacted: Bool

    public var passed: Bool {
        remoteTransmissionBlockedByDefault && sourceMutationBlocked && providerDefaultsPrivate && diagnosticsRedacted
    }
}

public struct PrivacyAudit: Sendable {
    public init() {}

    public func remoteTransmissionAllowed(url: URL, optedIn: Bool) -> Bool {
        ProviderTransportPolicy().decision(for: url, explicitRemoteOptIn: optedIn) == .allow
    }

    public func canTransmitToProvider(_ provider: ProviderSetting, explicitRemoteOptIn: Bool) -> Bool {
        ProviderTransportPolicy().decision(for: provider.baseURL, explicitRemoteOptIn: explicitRemoteOptIn) == .allow
    }

    public func sourceMutationAllowed(operation: String) -> Bool {
        let normalized = operation.lowercased()
        let forbidden = ["write", "rename", "move", "delete", "transcode", "metadata", "chmod", "sidecar"]
        return !forbidden.contains { normalized.contains($0) }
    }

    public func providerDefaultsArePrivate(_ providers: [ProviderSetting]) -> Bool {
        providers.allSatisfy { provider in
            switch provider.locality {
            case .localLoopback:
                if provider.id == "hermes-agent" { return provider.automaticIndexingEnabled == false }
                return true
            case .localNetwork, .remote:
                return provider.automaticIndexingEnabled == false && provider.transportState != .allowedLoopbackHTTP
            }
        }
    }

    public func diagnosticExportIsRedacted(_ data: Data, forbiddenFragments: [String]) -> Bool {
        guard let text = String(data: data, encoding: .utf8) else { return false }
        let lowercased = text.lowercased()
        return !forbiddenFragments.contains { !$0.isEmpty && lowercased.contains($0.lowercased()) }
            && lowercased.contains("omitted")
            && lowercased.contains("hashed")
    }

    public func makeReport(providers: [ProviderSetting], sampleRemoteURL: URL, diagnosticData: Data) -> PrivacyAuditReport {
        PrivacyAuditReport(
            remoteTransmissionBlockedByDefault: !remoteTransmissionAllowed(url: sampleRemoteURL, optedIn: false),
            sourceMutationBlocked: !sourceMutationAllowed(operation: "delete source media"),
            providerDefaultsPrivate: providerDefaultsArePrivate(providers),
            diagnosticsRedacted: diagnosticExportIsRedacted(diagnosticData, forbiddenFragments: [])
        )
    }
}
