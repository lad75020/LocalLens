# Contract: Search

## Query Input

```swift
struct SearchRequest: Sendable, Equatable {
    var query: String
    var mediaTypes: Set<MediaType>
    var watchedFolderIDs: Set<UUID>
    var limit: Int
    var includeMissing: Bool
}
```

Validation:
- Empty query shows recent/index status rather than running expensive semantic search.
- Very long query is truncated to configured safe length for provider use, while local lexical search can use normalized bounded text.
- Query text is treated as sensitive and excluded from diagnostics by default.

## Search Execution

1. Normalize query.
2. Run SQLite/FTS lexical search over filenames and chunks.
3. If embedding provider and compatible query model are available, generate query embedding locally and run vector candidate search.
4. Merge candidates.
5. Rank by weighted score.
6. Generate deterministic match reasons and snippets.
7. Exclude missing/stale files unless requested.

## Ranking Inputs

- FTS score for filename/OCR/PDF/transcript/visual labels.
- Vector similarity for semantic chunks.
- Media type relevance and exact phrase boosts.
- Page/timestamp context availability.
- Recency only as a light tie-breaker.
- Missing/stale penalties.

## Result Output

```swift
struct SearchResultDTO: Identifiable, Sendable, Equatable {
    let id: UUID
    let assetID: UUID
    let filename: String
    let mediaType: MediaType
    let folderContext: String
    let thumbnailID: UUID?
    let score: Double
    let matchReasons: [MatchReason]
    let snippet: String?
    let pageNumber: Int?
    let timestampStart: Double?
    let timestampEnd: Double?
    let isMissing: Bool
}

enum MatchReason: String, Codable, Sendable {
    case filename
    case visibleText
    case pdfText
    case transcript
    case visualLabel
    case semantic
}
```

## Performance Contract

- Already-indexed 10,000-asset library: first usable results under 500 ms for common queries on target hardware.
- UI search is debounced and cancellable.
- If semantic search is slow/unavailable, lexical results are shown first and semantic refinement may update the list.

## User Actions

Result actions:
- Preview with Quick Look.
- Reveal in Finder.
- Open with default app.
- Copy path.
- Copy relevant snippet.

Rules:
- Actions operate on original files without modification.
- Missing assets show safe recovery state rather than crashing.
