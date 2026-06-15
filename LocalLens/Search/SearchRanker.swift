import Foundation

public struct SearchCandidate: Equatable, Sendable {
    public var asset: MediaAsset
    public var folder: WatchedFolder?
    public var chunks: [SearchableChunk]
    public var lexicalScore: Double
    public var semanticScore: Double
    public var semanticChunkIDs: Set<UUID>

    public init(
        asset: MediaAsset,
        folder: WatchedFolder? = nil,
        chunks: [SearchableChunk] = [],
        lexicalScore: Double = 0,
        semanticScore: Double = 0,
        semanticChunkIDs: Set<UUID> = []
    ) {
        self.asset = asset
        self.folder = folder
        self.chunks = chunks
        self.lexicalScore = lexicalScore
        self.semanticScore = semanticScore
        self.semanticChunkIDs = semanticChunkIDs
    }
}

public struct SearchRanker: Sendable {
    public init() {}

    public func score(_ candidate: SearchCandidate, request: SearchRequest) -> Double {
        let normalizedQuery = request.normalizedQuery
        var value = candidate.lexicalScore + (candidate.semanticScore * 0.85)

        if !normalizedQuery.isEmpty {
            let filename = candidate.asset.filename.normalizedForSearch
            if filename == normalizedQuery { value += 8 }
            if filename.contains(normalizedQuery) { value += 5 }
            if candidate.chunks.contains(where: { $0.normalizedText.contains(normalizedQuery) }) { value += 3 }
        }

        if !request.mediaTypes.isEmpty, request.mediaTypes.contains(candidate.asset.mediaType) {
            value += 0.5
        }
        if candidate.chunks.contains(where: { $0.pageNumber != nil || $0.timestampStart != nil }) {
            value += 0.25
        }
        if candidate.asset.indexState == .missing || candidate.asset.indexState == .stale {
            value -= 20
        }
        if let modified = candidate.asset.modifiedAtFile {
            value += max(0, min(0.2, Date().timeIntervalSince(modified) / -86_400_000))
        }
        return value
    }

    public func ranked(_ candidates: [SearchCandidate], request: SearchRequest) -> [SearchCandidate] {
        candidates.sorted { lhs, rhs in
            let lhsScore = score(lhs, request: request)
            let rhsScore = score(rhs, request: request)
            if lhsScore == rhsScore { return lhs.asset.filename.localizedStandardCompare(rhs.asset.filename) == .orderedAscending }
            return lhsScore > rhsScore
        }
    }

    public func resultDTO(
        for candidate: SearchCandidate,
        request: SearchRequest,
        snippetBuilder: SnippetBuilder = SnippetBuilder()
    ) -> SearchResultDTO {
        let bestChunk = bestContextChunk(for: candidate, request: request)
        let snippet = bestChunk.flatMap { chunk in
            let value = snippetBuilder.snippet(text: chunk.text, around: request.normalizedQuery)
            return value.isEmpty ? nil : value
        }
        return SearchResultDTO(
            id: candidate.asset.id,
            assetID: candidate.asset.id,
            filename: candidate.asset.filename,
            mediaType: candidate.asset.mediaType,
            folderContext: candidate.folder?.displayName ?? candidate.folder?.displayPath ?? "Local media",
            thumbnailID: candidate.asset.thumbnailState == .complete ? candidate.asset.id : nil,
            score: score(candidate, request: request),
            matchReasons: matchReasons(for: candidate),
            snippet: snippet,
            pageNumber: bestChunk?.pageNumber,
            timestampStart: bestChunk?.timestampStart,
            timestampEnd: bestChunk?.timestampEnd,
            durationSeconds: candidate.asset.durationSeconds,
            isMissing: candidate.asset.indexState == .missing || candidate.asset.indexState == .stale
        )
    }

    public func matchReasons(for candidate: SearchCandidate) -> [MatchReason] {
        var ordered: [MatchReason] = []
        func add(_ reason: MatchReason) {
            if !ordered.contains(reason) { ordered.append(reason) }
        }
        if candidate.lexicalScore > 0, candidate.chunks.isEmpty { add(.filename) }
        for chunk in candidate.chunks {
            add(chunk.chunkType)
            if candidate.semanticChunkIDs.contains(chunk.id) { add(.semantic) }
        }
        if candidate.semanticScore > 0 { add(.semantic) }
        return ordered.isEmpty ? [.filename] : ordered
    }

    public func bestContextChunk(for candidate: SearchCandidate, request: SearchRequest) -> SearchableChunk? {
        let query = request.normalizedQuery
        return candidate.chunks.sorted { lhs, rhs in
            let lhsExact = query.isEmpty ? false : lhs.normalizedText.contains(query)
            let rhsExact = query.isEmpty ? false : rhs.normalizedText.contains(query)
            if lhsExact != rhsExact { return lhsExact }
            let lhsSemantic = candidate.semanticChunkIDs.contains(lhs.id)
            let rhsSemantic = candidate.semanticChunkIDs.contains(rhs.id)
            if lhsSemantic != rhsSemantic { return lhsSemantic }
            let lhsConfidence = lhs.confidence ?? 0
            let rhsConfidence = rhs.confidence ?? 0
            if lhsConfidence == rhsConfidence { return lhs.id.uuidString < rhs.id.uuidString }
            return lhsConfidence > rhsConfidence
        }.first
    }
}

public extension String {
    var normalizedForSearch: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
