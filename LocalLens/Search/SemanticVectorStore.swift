import Foundation

public struct SemanticVectorCandidate: Equatable, Sendable, Identifiable {
    public var id: UUID { chunk.id }
    public let chunk: SearchableChunk
    public let similarity: Double
    public let modelID: String
}

public struct SemanticQueryEmbedding: Equatable, Sendable {
    public let vector: [Float]
    public let modelID: String
    public let providerID: String
}

public struct SemanticVectorStore: Sendable {
    public init() {}

    public func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        for index in a.indices {
            dot += a[index] * b[index]
            normA += a[index] * a[index]
            normB += b[index] * b[index]
        }
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (sqrt(normA) * sqrt(normB))
    }

    public func candidates(
        for queryEmbedding: SemanticQueryEmbedding?,
        chunks: [SearchableChunk],
        limit: Int = BuildConfiguration.maxSearchResults,
        minimumSimilarity: Double = 0.001
    ) -> [SemanticVectorCandidate] {
        guard let queryEmbedding, !queryEmbedding.vector.isEmpty else { return [] }
        let boundedLimit = max(1, min(limit, BuildConfiguration.maxSearchResults))

        return chunks.compactMap { chunk -> SemanticVectorCandidate? in
            guard let embedding = chunk.embedding,
                  let embeddingModel = chunk.embeddingModel,
                  embeddingModel == queryEmbedding.modelID,
                  embedding.count == queryEmbedding.vector.count else {
                return nil
            }
            let score = Double(cosine(queryEmbedding.vector, embedding))
            guard score >= minimumSimilarity else { return nil }
            return SemanticVectorCandidate(chunk: chunk, similarity: score, modelID: embeddingModel)
        }
        .sorted { lhs, rhs in
            if lhs.similarity == rhs.similarity { return lhs.chunk.id.uuidString < rhs.chunk.id.uuidString }
            return lhs.similarity > rhs.similarity
        }
        .prefix(boundedLimit)
        .map { $0 }
    }

    public func queryEmbedding(
        for request: SearchRequest,
        providers: [ProviderSetting],
        clientFactory: @Sendable (ProviderSetting) -> any EmbeddingClient = { provider in
            OpenAICompatibleClient(baseURL: provider.baseURL, providerID: provider.id)
        }
    ) async -> SemanticQueryEmbedding? {
        let normalizedQuery = request.normalizedQuery
        guard !normalizedQuery.isEmpty else { return nil }
        guard let provider = providers.first(where: Self.isEligibleLocalEmbeddingProvider) else { return nil }
        guard let modelID = provider.modelIDs.first else { return nil }

        do {
            let embeddings = try await clientFactory(provider).embeddings(model: modelID, inputs: [request.boundedProviderQuery])
            guard let vector = embeddings.first, !vector.isEmpty else { return nil }
            return SemanticQueryEmbedding(vector: vector, modelID: modelID, providerID: provider.id)
        } catch is CancellationError {
            return nil
        } catch {
            return nil
        }
    }

    public static func isEligibleLocalEmbeddingProvider(_ provider: ProviderSetting) -> Bool {
        provider.isEnabled
            && provider.automaticIndexingEnabled
            && provider.locality == .localLoopback
            && provider.transportState == .allowedLoopbackHTTP
            && !provider.modelIDs.isEmpty
    }
}
