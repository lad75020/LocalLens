import XCTest
@testable import LocalLens

final class SemanticVectorStoreTests: XCTestCase {
    func testCosineCandidateScoringIsDeterministic() {
        let store = SemanticVectorStore()
        let assetID = UUID()
        let close = SearchTestSupport.chunk(assetID: assetID, type: .semantic, text: "coastal sunset", embedding: [1, 0], embeddingModel: "local-embed")
        let far = SearchTestSupport.chunk(assetID: assetID, type: .semantic, text: "city skyline", embedding: [0, 1], embeddingModel: "local-embed")
        let query = SemanticQueryEmbedding(vector: [0.9, 0.1], modelID: "local-embed", providerID: "local")

        let candidates = store.candidates(for: query, chunks: [far, close], limit: 10, minimumSimilarity: 0)

        XCTAssertEqual(candidates.map(\.chunk.id), [close.id, far.id])
        XCTAssertGreaterThan(candidates[0].similarity, candidates[1].similarity)
    }

    func testNoProviderFallbackSkipsQueryEmbedding() async {
        let request = SearchRequest(query: "sunset")
        let remote = ProviderSetting(
            id: "remote",
            displayName: "Remote",
            baseURL: URL(string: "https://example.com/v1")!,
            isEnabled: true,
            automaticIndexingEnabled: true,
            locality: .remote,
            transportState: .requiresHTTPS,
            credentialState: .missingRequired,
            modelIDs: ["embed"],
            lastHealthCheckAt: nil,
            lastHealthStatus: .healthy
        )

        let embedding = await SemanticVectorStore().queryEmbedding(for: request, providers: [remote])
        XCTAssertNil(embedding)
    }

    func testDimensionAndModelMismatchAreExcluded() {
        let store = SemanticVectorStore()
        let assetID = UUID()
        let wrongDimension = SearchTestSupport.chunk(assetID: assetID, type: .semantic, text: "wrong", embedding: [1, 2, 3], embeddingModel: "local-embed")
        let wrongModel = SearchTestSupport.chunk(assetID: assetID, type: .semantic, text: "wrong model", embedding: [1, 0], embeddingModel: "other-model")
        let query = SemanticQueryEmbedding(vector: [1, 0], modelID: "local-embed", providerID: "local")

        XCTAssertTrue(store.candidates(for: query, chunks: [wrongDimension, wrongModel]).isEmpty)
    }
}
