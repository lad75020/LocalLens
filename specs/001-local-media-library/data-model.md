# Data Model: LocalLens Private Media Library MVP

## Overview

LocalLens stores all MVP state locally. The source media library remains read-only; the database and caches can be deleted or rebuilt without changing source files.

## Entity: WatchedFolder

Represents a user-authorized folder root.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| displayName | String | Last known folder name |
| bookmarkData | Data | Security-scoped bookmark data |
| originalPathHash | String | Hashed path for diagnostics/search context |
| displayPath | String | UI path, redacted in diagnostics |
| isEnabled | Bool | Disabled folders are not scanned |
| authorizationState | enum | authorized, staleBookmark, denied, missing, externalUnavailable, needsReauthorization |
| lastScanStartedAt | Date? | For status UI |
| lastScanCompletedAt | Date? | For status UI |
| createdAt | Date | Audit/history |
| updatedAt | Date | Audit/history |

Relationships:
- Has many `MediaAsset` records.
- Has many discovery `IndexJob` records.

Validation:
- Bookmark access must be started/stopped through `FolderAuthorizationService` only.
- Removing a watched folder removes index records for that folder after user confirmation, but does not delete source files.

## Entity: MediaAsset

Represents one discovered supported source file.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| watchedFolderID | UUID | Parent folder |
| fileIdentity | String | File resource identifier/inode-like identity where available |
| pathRelativeToFolder | String | Stored for reveal/open; redacted in diagnostics |
| pathHash | String | Diagnostics-safe identity |
| filename | String | Searchable |
| mediaType | enum | image, pdf, audio, video |
| contentType | String | UTType identifier |
| sizeBytes | Int64 | File metadata |
| createdAtFile | Date? | File metadata |
| modifiedAtFile | Date? | File metadata |
| indexedFileSignature | String | Size/date/hash where feasible to detect changes |
| dimensions | String? | Image/video dimensions |
| durationSeconds | Double? | Audio/video duration |
| pageCount | Int? | PDF page count |
| thumbnailState | enum | missing, queued, generated, failed |
| indexState | enum | discovered, queued, indexing, partial, complete, failed, cancelled, missing, stale |
| lastIndexedAt | Date? | Completion timestamp |
| createdAt | Date | DB record timestamp |
| updatedAt | Date | DB record timestamp |

Relationships:
- Has many `ExtractionRecord`, `SearchableChunk`, `IndexFailure`, and `IndexJob` records.

Rules:
- `complete` only after required MVP stages for that media type are completed or intentionally skipped with a safe partial reason.
- Missing files are marked missing or excluded from results without crashing.

## Entity: ExtractionRecord

Represents one extraction output from a source asset.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| assetID | UUID | Parent asset |
| stage | enum | thumbnail, metadata, imageOCR, imageLabels, pdfText, pdfOCR, audioTranscript, videoTranscript, videoKeyframe, sceneLabels, embeddings |
| providerID | String? | AppleVision, PDFKit, AVFoundation, omlx, ollama, hermes-agent, custom |
| providerMode | enum | localFramework, localLoopback, remoteOptIn |
| status | enum | queued, running, succeeded, partial, failed, cancelled |
| outputSummary | String? | Short safe summary for UI |
| confidence | Double? | Optional stage confidence |
| pageNumber | Int? | PDF/page context |
| timestampStart | Double? | Audio/video context |
| timestampEnd | Double? | Audio/video context |
| errorCategory | String? | Safe failure category |
| createdAt | Date | Audit |
| updatedAt | Date | Audit |

Rules:
- Raw extracted text lives in `SearchableChunk`, not in diagnostic logs.
- Provider raw responses are not persisted unless explicitly needed and then only in app-private storage with size bounds.

## Entity: SearchableChunk

Represents text-like or semantic searchable material.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| assetID | UUID | Parent asset |
| extractionRecordID | UUID? | Source extraction |
| chunkType | enum | filename, ocrText, pdfText, transcript, visualLabel, sceneDescription, semanticSummary |
| text | String | FTS indexed; bounded per chunk |
| normalizedText | String | Optional normalized text |
| embedding | Blob? | Float16/Float32 normalized vector if available |
| embeddingModel | String? | Provider/model identifier |
| pageNumber | Int? | PDF context |
| timestampStart | Double? | Media context |
| timestampEnd | Double? | Media context |
| confidence | Double? | Optional |
| createdAt | Date | Audit |

Indexes:
- FTS5 over `filename`, `text`, `visualLabel`, `transcript`, and `pdfText` chunks.
- Vector index/table over `embedding` where model dimensions match.

Rules:
- Chunks are bounded to avoid storing enormous transcripts in one row.
- Snippets are generated from chunks and must not reveal unrelated content.

## Entity: IndexJob

Represents work to discover or index files.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| jobType | enum | discoverFolder, indexAsset, extractThumbnail, extractText, transcribe, sampleVideo, embedChunks, reindexAsset, reindexFolder, cleanupMissing |
| watchedFolderID | UUID? | Folder context |
| assetID | UUID? | Asset context |
| priority | Int | User-triggered reindex > normal discovery |
| status | enum | queued, running, paused, succeeded, failed, cancelled |
| attemptCount | Int | Retry support |
| lastErrorCategory | String? | Safe failure category |
| progressUnit | String? | files, pages, seconds, chunks |
| progressCompleted | Int | Bounded progress |
| progressTotal | Int? | Optional |
| createdAt | Date | Audit |
| startedAt | Date? | Audit |
| completedAt | Date? | Audit |

Rules:
- Jobs are resumable across relaunch.
- Cancelling a running job does not mark extraction complete.
- Pause prevents new jobs from starting but lets safe checkpointing finish.

## Entity: IndexFailure

Represents a safe, user-visible failure.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| assetID | UUID? | Optional asset context |
| watchedFolderID | UUID? | Optional folder context |
| stage | String | Failing stage |
| category | enum | permissionDenied, staleBookmark, missingFile, unsupportedMedia, corruptedMedia, passwordProtectedPDF, modelUnavailable, providerTimeout, transportBlocked, cancelled, storageFull, databaseError, unknownRedacted |
| retryability | enum | retry, reauthorize, ignore, rebuildIndex, notRetryable |
| safeMessage | String | User-facing, redacted |
| rawDebugReference | String? | Internal reference id, not raw body |
| createdAt | Date | Audit |
| resolvedAt | Date? | Audit |

Rules:
- No raw extracted content, credentials, full transcripts, or raw provider bodies in `safeMessage`.
- Full path display is allowed in app UI when useful, but diagnostic export redacts/hash paths by default.

## Entity: ProviderSetting

Represents local or remote AI provider configuration.

| Field | Type | Notes |
|---|---|---|
| id | String | omlx, ollama, hermes-agent, custom |
| displayName | String | User-facing name |
| baseURL | URL | Normalized base URL, usually ending before `/v1` internally |
| apiCompatibility | enum | openAIChat, openAIEmbeddings, openAIResponses, ollamaNativeOptional |
| isEnabled | Bool | Whether provider can be used |
| automaticIndexingEnabled | Bool | Whether bulk indexing may call provider |
| locality | enum | localLoopback, localNetwork, remote |
| transportState | enum | allowedLoopbackHTTP, requiresHTTPS, blockedHTTP, invalidURL |
| credentialState | enum | noneNeeded, keyInKeychain, missingRequired |
| modelIDs | [String] | Cached health/model list |
| lastHealthCheckAt | Date? | Provider health |
| lastHealthStatus | enum | unknown, healthy, unavailable, blocked, unauthorized |

Rules:
- Default provider rows: oMLX enabled/configurable at `http://localhost:17998/v1`, Ollama enabled/configurable at `http://localhost:11434/v1`, Hermes Agent visible but not automatic for bulk indexing by default at `http://localhost:8642/v1`, custom remote disabled.
- Credentials are stored in Keychain, never in SQLite/plaintext settings.

## Entity: SearchQuery

Transient or optionally persisted recent query.

| Field | Type | Notes |
|---|---|---|
| queryText | String | User input |
| mediaFilters | [MediaType] | Optional filters |
| folderFilters | [UUID] | Optional filters |
| limit | Int | Default bounded result count |
| includeMissing | Bool | Default false |

Rules:
- Query text can be sensitive and is not included in diagnostics by default.
- Query length is bounded before search/provider use.

## Entity: SearchResult

Computed result returned by search.

| Field | Type | Notes |
|---|---|---|
| assetID | UUID | Source asset |
| filename | String | Display |
| mediaType | enum | Display/filter |
| thumbnailURL | URL? | Local cache |
| folderContext | String | Display path context |
| score | Double | Combined rank |
| matchReasons | [enum] | filename, visibleText, pdfText, transcript, visualLabel, semantic |
| snippet | String? | Redacted bounded snippet |
| pageNumber | Int? | Context |
| timestampStart | Double? | Context |
| actions | [enum] | preview, reveal, open, copyPath, copySnippet |

Rules:
- Results must exclude missing assets unless explicitly showing stale/missing state.
- Match reasons are deterministic and traceable to chunks/extractions.
