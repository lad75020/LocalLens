import Foundation

public struct OpenAICompatibleClient: Sendable {
    public let baseURL: URL
    public let credentialStore: ProviderCredentialStore
    public let providerID: String
    public let session: URLSession
    public let redactionPolicy: RedactionPolicy

    public init(baseURL: URL, providerID: String, credentialStore: ProviderCredentialStore = ProviderCredentialStore(), session: URLSession = .shared, redactionPolicy: RedactionPolicy = RedactionPolicy()) {
        self.baseURL = baseURL; self.providerID = providerID; self.credentialStore = credentialStore; self.session = session; self.redactionPolicy = redactionPolicy
    }

    public func models() async throws -> [String] {
        let data = try await request(path: "models", method: "GET", body: nil)
        let decoded = try? JSONDecoder().decode(ModelListResponse.self, from: data)
        return decoded?.data.map(\.id) ?? []
    }

    public func embeddings(model: String, inputs: [String]) async throws -> [[Float]] {
        let body = try JSONEncoder().encode(EmbeddingsRequest(model: model, input: inputs.map { String($0.prefix(BuildConfiguration.maxPromptCharacters)) }, encoding_format: "float"))
        let data = try await request(path: "embeddings", method: "POST", body: body)
        return (try JSONDecoder().decode(EmbeddingsResponse.self, from: data)).data.sorted { $0.index < $1.index }.map(\.embedding)
    }

    public func chatJSON(model: String, payload: String) async throws -> Data {
        let messages = [ChatMessage(role: "system", content: PromptTemplates.systemMetadataExtractor), ChatMessage(role: "user", content: String(payload.prefix(BuildConfiguration.maxPromptCharacters)))]
        let body = try JSONEncoder().encode(ChatRequest(model: model, messages: messages, temperature: 0, response_format: ["type": "json_object"]))
        return try await request(path: "chat/completions", method: "POST", body: body)
    }

    private func request(path: String, method: String, body: Data?) async throws -> Data {
        var url = baseURL
        if !url.path.hasSuffix(path) { url.append(path: path) }
        var request = URLRequest(url: url, timeoutInterval: BuildConfiguration.providerTimeoutSeconds)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = try credentialStore.read(providerID: providerID), !key.isEmpty { request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw ProviderClientError.requestFailed(redactionPolicy.safeMessage("HTTP provider error")) }
            return data
        } catch is CancellationError { throw ProviderClientError.cancelled }
        catch let error as ProviderClientError { throw error }
        catch { throw ProviderClientError.requestFailed(redactionPolicy.safeMessage(error.localizedDescription)) }
    }
}

public enum ProviderClientError: Error, Equatable, Sendable { case cancelled, requestFailed(String) }
private struct ModelListResponse: Decodable { struct Model: Decodable { let id: String }; let data: [Model] }
private struct EmbeddingsRequest: Encodable { let model: String; let input: [String]; let encoding_format: String }
private struct EmbeddingsResponse: Decodable { struct Item: Decodable { let index: Int; let embedding: [Float] }; let data: [Item] }
private struct ChatMessage: Codable { let role: String; let content: String }
private struct ChatRequest: Encodable { let model: String; let messages: [ChatMessage]; let temperature: Double; let response_format: [String: String] }
