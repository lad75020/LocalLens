import Foundation

public struct PrivacyAudit: Sendable { public init() {}; public func remoteTransmissionAllowed(url: URL, optedIn: Bool) -> Bool { ProviderTransportPolicy().decision(for: url, explicitRemoteOptIn: optedIn) == .allow } }
