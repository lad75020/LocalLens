import Foundation

public struct OfficeDocumentExtractor: Sendable {
    public let credentialStore: ProviderCredentialStore
    public let redactionPolicy: RedactionPolicy
    public let clientFactory: @Sendable (ProviderSetting) -> OpenAICompatibleClient

    public init(
        credentialStore: ProviderCredentialStore = ProviderCredentialStore(),
        redactionPolicy: RedactionPolicy = RedactionPolicy(),
        clientFactory: @escaping @Sendable (ProviderSetting) -> OpenAICompatibleClient = { provider in
            OpenAICompatibleClient(baseURL: provider.baseURL, providerID: provider.id)
        }
    ) {
        self.credentialStore = credentialStore
        self.redactionPolicy = redactionPolicy
        self.clientFactory = clientFactory
    }

    public func extract(from url: URL, asset: MediaAsset, provider: ProviderSetting, hermesProfile: HermesProfileSelectionState) async throws -> OfficeDocumentExtractionResult {
        guard provider.id == "hermes-agent" else {
            throw ExtractionFailure.failed(category: .transportBlocked, retryability: .notRetryable, safeMessage: "Office documents are routed only to Hermes Agent.")
        }
        guard let profileID = hermesProfile.selectedProfileID, hermesProfile.isReadyForOfficeIndexing else {
            throw ExtractionFailure.failed(category: .modelUnavailable, retryability: .retry, safeMessage: "Select an available Hermes Agent profile before indexing Office documents.")
        }
        guard let kind = OfficeDocumentKind(rawValue: url.pathExtension.lowercased()) else {
            throw ExtractionFailure.failed(category: .unsupportedMedia, retryability: .ignore, safeMessage: "Unsupported Office document type.")
        }

        let reference = try boundedDocumentReference(for: url, asset: asset)
        let payload = PromptTemplates.officePayload(kind: kind, filename: asset.filename, documentTextOrReference: reference)
        let model = provider.effectiveModelID ?? "hermes-agent"
        do {
            let data = try await clientFactory(provider).chatJSON(model: model, payload: payload, hermesProfileID: profileID)
            let parsed = Self.parseSearchableResponse(data)
            return OfficeDocumentExtractionResult(
                officeKind: kind,
                providerID: provider.id,
                hermesProfileID: profileID,
                searchableText: parsed.searchableText,
                safeSummary: parsed.safeSummary,
                safeSnippet: parsed.safeSnippet,
                failureCategory: nil
            )
        } catch is CancellationError {
            throw ExtractionFailure.failed(category: .cancelled, retryability: .retry, safeMessage: "Office indexing was cancelled.")
        } catch let error as ProviderClientError {
            switch error {
            case .cancelled:
                throw ExtractionFailure.failed(category: .cancelled, retryability: .retry, safeMessage: "Office indexing was cancelled.")
            case .requestFailed(let message):
                throw ExtractionFailure.failed(category: message.localizedCaseInsensitiveContains("timed") ? .providerTimeout : .modelUnavailable, retryability: .retry, safeMessage: redactionPolicy.safeMessage(message))
            }
        } catch {
            throw ExtractionFailure.failed(category: .modelUnavailable, retryability: .retry, safeMessage: "Hermes Agent Office extraction failed safely.")
        }
    }

    private func boundedDocumentReference(for url: URL, asset: MediaAsset) throws -> String {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let bounded = data.prefix(BuildConfiguration.maxPromptCharacters)
        if let text = String(data: Data(bounded), encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return "Office document reference: filename=\(asset.filename); extension=\(url.pathExtension.lowercased()); size_bytes=\(asset.sizeBytes); path_hash=\(asset.pathHash). Source bytes are read-only and not modified."
    }

    private static func parseSearchableResponse(_ data: Data) -> (searchableText: String, safeSummary: String?, safeSnippet: String?) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let text = String(data: data, encoding: .utf8).map { String($0.prefix(1_000)) } ?? ""
            return (text, nil, text.isEmpty ? nil : text)
        }
        let content: String
        if let direct = root["searchableText"] as? String { content = direct }
        else if let direct = root["searchable_text"] as? String { content = direct }
        else if let choices = root["choices"] as? [[String: Any]], let first = choices.first, let message = first["message"] as? [String: Any], let messageContent = message["content"] as? String { content = messageContent }
        else { content = "" }
        let summary = (root["safeSummary"] as? String) ?? (root["summary"] as? String)
        let snippet = (root["safeSnippet"] as? String) ?? (root["snippet"] as? String) ?? (content.isEmpty ? nil : String(content.prefix(500)))
        return (String(content.prefix(BuildConfiguration.maxPromptCharacters)), summary.map { String($0.prefix(500)) }, snippet.map { String($0.prefix(500)) })
    }
}
