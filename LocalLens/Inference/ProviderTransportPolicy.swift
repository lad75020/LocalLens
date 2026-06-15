import Foundation

public enum ProviderTransportDecision: Equatable, Sendable { case allow, requireExplicitRemoteOptIn, blockPlainHTTPNonLoopback, invalidURL }

public struct ProviderTransportPolicy: Sendable {
    public init() {}
    public func normalize(_ raw: String) -> URL? {
        let repaired = raw.replacingOccurrences(of: "http://localhost://", with: "http://localhost:")
        guard var components = URLComponents(string: repaired), let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme), components.host != nil else { return nil }
        if components.path.isEmpty { components.path = "/v1" }
        return components.url
    }
    public func locality(for url: URL) -> ProviderLocality {
        guard let host = url.host(percentEncoded: false)?.lowercased() else { return .remote }
        if ["localhost", "127.0.0.1", "::1"].contains(host) { return .localLoopback }
        if host.hasSuffix(".local") || host.hasPrefix("192.168.") || host.hasPrefix("10.") || host.range(of: #"^172\.(1[6-9]|2[0-9]|3[0-1])\."#, options: .regularExpression) != nil { return .localNetwork }
        return .remote
    }
    public func decision(for url: URL, explicitRemoteOptIn: Bool = false, unsafeDevelopmentOverride: Bool = false) -> ProviderTransportDecision {
        guard let scheme = url.scheme?.lowercased() else { return .invalidURL }
        let locality = locality(for: url)
        if scheme == "http" && locality == .localLoopback { return .allow }
        if scheme == "http" && unsafeDevelopmentOverride { return .allow }
        if scheme == "http" { return .blockPlainHTTPNonLoopback }
        if scheme == "https" && locality != .localLoopback && !explicitRemoteOptIn { return .requireExplicitRemoteOptIn }
        if scheme == "https" { return .allow }
        return .invalidURL
    }
    public func transportState(for url: URL, explicitRemoteOptIn: Bool = false) -> TransportState {
        switch decision(for: url, explicitRemoteOptIn: explicitRemoteOptIn) {
        case .allow where url.scheme == "http": return .allowedLoopbackHTTP
        case .allow: return .requiresHTTPS
        case .requireExplicitRemoteOptIn: return .requiresHTTPS
        case .blockPlainHTTPNonLoopback: return .blockedHTTP
        case .invalidURL: return .invalidURL
        }
    }
}
