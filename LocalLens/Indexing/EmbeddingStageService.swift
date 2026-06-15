import Foundation

public struct EmbeddingStageService: Sendable {
    public init() {}

    public func embed(
        chunks: [SearchableChunk],
        providers: [ProviderSetting],
        clientFactory: @Sendable (ProviderSetting) -> any EmbeddingClient = { provider in
            OpenAICompatibleClient(baseURL: provider.baseURL, providerID: provider.id)
        }
    ) async -> EmbeddingStageResult {
        guard !chunks.isEmpty else {
            return EmbeddingStageResult(chunks: [], providerID: nil, state: .complete, failureCategory: nil)
        }

        guard let provider = providers.first(where: { setting in
            setting.isEnabled
                && setting.automaticIndexingEnabled
                && setting.locality == .localLoopback
                && setting.transportState == .allowedLoopbackHTTP
                && !setting.modelIDs.isEmpty
        }) else {
            return EmbeddingStageResult(chunks: chunks, providerID: nil, state: .complete, failureCategory: nil)
        }

        do {
            let model = provider.modelIDs[0]
            let inputs = chunks.map { String($0.text.prefix(BuildConfiguration.maxPromptCharacters)) }
            let embeddings = try await clientFactory(provider).embeddings(model: model, inputs: inputs)
            guard embeddings.count == chunks.count else {
                return EmbeddingStageResult(chunks: chunks, providerID: provider.id, state: .partial, failureCategory: .modelUnavailable)
            }
            let embedded = zip(chunks, embeddings).map { chunk, embedding in
                SearchableChunk(
                    id: chunk.id,
                    assetID: chunk.assetID,
                    extractionRecordID: chunk.extractionRecordID,
                    chunkType: chunk.chunkType,
                    text: chunk.text,
                    normalizedText: chunk.normalizedText,
                    embedding: embedding,
                    embeddingModel: model,
                    pageNumber: chunk.pageNumber,
                    timestampStart: chunk.timestampStart,
                    timestampEnd: chunk.timestampEnd,
                    confidence: chunk.confidence,
                    createdAt: chunk.createdAt
                )
            }
            return EmbeddingStageResult(chunks: embedded, providerID: provider.id, state: .complete, failureCategory: nil)
        } catch is CancellationError {
            return EmbeddingStageResult(chunks: chunks, providerID: provider.id, state: .cancelled, failureCategory: .cancelled)
        } catch {
            return EmbeddingStageResult(chunks: chunks, providerID: provider.id, state: .partial, failureCategory: .modelUnavailable)
        }
    }
}
