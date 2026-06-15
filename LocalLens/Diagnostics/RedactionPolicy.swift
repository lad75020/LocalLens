import CryptoKit
import Foundation

public struct RedactionPolicy: Sendable {
    public init() {}
    public func redactPath(_ path: String) -> String { "path#" + sha256(path).prefix(12) }
    public func redactCredential(_ value: String?) -> String { value?.isEmpty == false ? "<redacted credential>" : "<none>" }
    public func redactExtractedContent(_ value: String) -> String { value.isEmpty ? "" : "<omitted private media content>" }
    public func redactProviderBody(_ value: Data) -> String { value.isEmpty ? "" : "<omitted provider body: \(value.count) bytes>" }
    public func redactPrompt(_ value: String) -> String { value.isEmpty ? "" : "<omitted prompt: \(value.count) characters>" }
    public func redactOfficeText(_ value: String) -> String { value.isEmpty ? "" : "<omitted Office document text>" }
    public func redactModelOrProfileError(_ value: String) -> String { safeMessage(value, maxCharacters: 160) }
    public func safeMessage(_ message: String, maxCharacters: Int = 160) -> String { String(message.replacingOccurrences(of: #"(/[A-Za-z0-9_ .-]+)+"#, with: "<path>", options: .regularExpression).prefix(maxCharacters)) }
    private func sha256(_ text: String) -> String { SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined() }
}
