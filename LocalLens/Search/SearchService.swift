import Foundation

public actor SearchService {
    public typealias EmbeddingClientFactory = @Sendable (ProviderSetting) -> any EmbeddingClient

    private let vectorStore: SemanticVectorStore
    private let ranker: SearchRanker
    private let snippetBuilder: SnippetBuilder
    private let embeddingClientFactory: EmbeddingClientFactory

    public init(
        vectorStore: SemanticVectorStore = SemanticVectorStore(),
        ranker: SearchRanker = SearchRanker(),
        snippetBuilder: SnippetBuilder = SnippetBuilder(),
        embeddingClientFactory: @escaping EmbeddingClientFactory = { provider in
            OpenAICompatibleClient(baseURL: provider.baseURL, providerID: provider.id)
        }
    ) {
        self.vectorStore = vectorStore
        self.ranker = ranker
        self.snippetBuilder = snippetBuilder
        self.embeddingClientFactory = embeddingClientFactory
    }

    public func search(
        _ request: SearchRequest,
        storage: StorageRepositories,
        providers explicitProviders: [ProviderSetting]? = nil
    ) async -> [SearchResultDTO] {
        guard !request.isEmpty else { return [] }

        do {
            let providers: [ProviderSetting]
            if let explicitProviders {
                providers = explicitProviders
            } else {
                providers = try await storage.providers.list()
            }
            let folders = try await storage.watchedFolders.list()
            let folderByID = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0) })
            let assets = try await storage.assets.list(watchedFolderID: nil)
                .filter { asset in assetMatchesRequest(asset, request: request) }
                .filter { asset in request.includeMissing || !isMissing(asset: asset, folder: folderByID[asset.watchedFolderID]) }

            try Task.checkCancellation()
            let normalizedQuery = request.normalizedQuery
            let terms = SnippetBuilder.queryTerms(normalizedQuery)
            var candidateByAssetID: [UUID: SearchCandidate] = [:]
            var allChunks: [SearchableChunk] = []
            let ftsChunks = (try? await storage.chunks.searchText(normalizedQuery, limit: max(request.limit * 8, request.limit))) ?? []
            let ftsChunkIDs = Set(ftsChunks.map(\.id))
            let ftsAssetIDs = Set(ftsChunks.map(\.assetID))

            for asset in assets {
                let chunks = try await storage.chunks.list(assetID: asset.id)
                allChunks.append(contentsOf: chunks)
                var matchedChunks = matchingChunks(chunks, normalizedQuery: normalizedQuery, terms: terms)
                for ftsChunk in ftsChunks where ftsChunk.assetID == asset.id && !matchedChunks.contains(where: { $0.id == ftsChunk.id }) {
                    matchedChunks.append(ftsChunk)
                }
                var lexicalScore = lexicalScore(asset: asset, chunks: chunks, normalizedQuery: normalizedQuery, terms: terms)
                if ftsAssetIDs.contains(asset.id) { lexicalScore += 4 }
                if chunks.contains(where: { ftsChunkIDs.contains($0.id) }) { lexicalScore += 1 }
                if lexicalScore > 0 {
                    candidateByAssetID[asset.id] = SearchCandidate(
                        asset: asset,
                        folder: folderByID[asset.watchedFolderID],
                        chunks: matchedChunks,
                        lexicalScore: lexicalScore
                    )
                }
            }

            try Task.checkCancellation()
            if let queryEmbedding = await vectorStore.queryEmbedding(for: request, providers: providers, clientFactory: embeddingClientFactory) {
                let semanticCandidates = vectorStore.candidates(for: queryEmbedding, chunks: allChunks, limit: max(request.limit * 4, request.limit))
                for semanticCandidate in semanticCandidates {
                    guard let asset = assets.first(where: { $0.id == semanticCandidate.chunk.assetID }) else { continue }
                    var candidate = candidateByAssetID[asset.id] ?? SearchCandidate(
                        asset: asset,
                        folder: folderByID[asset.watchedFolderID],
                        chunks: []
                    )
                    if !candidate.chunks.contains(where: { $0.id == semanticCandidate.chunk.id }) {
                        candidate.chunks.append(semanticCandidate.chunk)
                    }
                    candidate.semanticScore = max(candidate.semanticScore, semanticCandidate.similarity * 10)
                    candidate.semanticChunkIDs.insert(semanticCandidate.chunk.id)
                    candidateByAssetID[asset.id] = candidate
                }
            }

            return ranker.ranked(Array(candidateByAssetID.values), request: request)
                .prefix(request.limit)
                .map { ranker.resultDTO(for: $0, request: request, snippetBuilder: snippetBuilder) }
        } catch is CancellationError {
            return []
        } catch {
            return []
        }
    }

    public func search(_ request: SearchRequest) async -> [SearchResultDTO] { [] }

    private func assetMatchesRequest(_ asset: MediaAsset, request: SearchRequest) -> Bool {
        (request.mediaTypes.isEmpty || request.mediaTypes.contains(asset.mediaType))
            && (request.watchedFolderIDs.isEmpty || request.watchedFolderIDs.contains(asset.watchedFolderID))
    }

    private func lexicalScore(asset: MediaAsset, chunks: [SearchableChunk], normalizedQuery: String, terms: [String]) -> Double {
        var score: Double = 0
        let filename = asset.filename.normalizedForSearch
        if filename == normalizedQuery { score += 12 }
        if filename.contains(normalizedQuery) { score += 6 }
        for term in terms where filename.contains(term) { score += 1.5 }

        for chunk in chunks {
            let text = chunk.normalizedText.isEmpty ? chunk.text.normalizedForSearch : chunk.normalizedText
            if text.contains(normalizedQuery) { score += weight(for: chunk.chunkType) * 2 }
            for term in terms where text.contains(term) { score += weight(for: chunk.chunkType) }
        }
        return score
    }

    private func matchingChunks(_ chunks: [SearchableChunk], normalizedQuery: String, terms: [String]) -> [SearchableChunk] {
        chunks.filter { chunk in
            let text = chunk.normalizedText.isEmpty ? chunk.text.normalizedForSearch : chunk.normalizedText
            if !normalizedQuery.isEmpty, text.contains(normalizedQuery) { return true }
            return terms.contains { text.contains($0) }
        }
    }

    private func weight(for reason: MatchReason) -> Double {
        switch reason {
        case .filename: 4
        case .visibleText: 3
        case .pdfText: 3
        case .imageDescription: 3.2
        case .pdfSummary: 2.9
        case .transcript: 2.8
        case .visualLabel: 2.2
        case .officeText: 3.1
        case .officeSummary: 2.7
        case .semantic: 1.5
        }
    }

    private func isMissing(asset: MediaAsset, folder: WatchedFolder?) -> Bool {
        if asset.indexState == .missing || asset.indexState == .stale { return true }
        guard let folder else { return false }
        let displayPath = folder.displayPath
        guard displayPath.hasPrefix("/"), !displayPath.localizedCaseInsensitiveContains("redacted") else { return false }
        let folderExists = FileManager.default.fileExists(atPath: displayPath)
        guard folderExists else { return false }
        return !FileManager.default.fileExists(atPath: URL(fileURLWithPath: displayPath).appendingPathComponent(asset.pathRelativeToFolder).path)
    }
}
