import Foundation
import Security

public struct ProviderCredentialStore: Sendable {
    private let service = "LocalLens.ProviderCredentialStore"
    public init() {}

    public func save(apiKey: String, providerID: String) throws {
        let data = Data(apiKey.utf8)
        var query: [String: Any] = baseQuery(providerID)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    public func read(providerID: String) throws -> String? {
        var query = baseQuery(providerID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw KeychainError(status: status) }
        return String(data: data, encoding: .utf8)
    }

    public func delete(providerID: String) throws {
        let status = SecItemDelete(baseQuery(providerID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    private func baseQuery(_ providerID: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: providerID]
    }
}

public struct KeychainError: Error, Equatable, Sendable { public let status: OSStatus }
