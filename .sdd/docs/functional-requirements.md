# Functional Requirements

This document consolidates functional behavior from the LocalLens feature specs and implementation evidence. Confidence markers indicate the strength of the evidence.

## 1. Private Local Media Library

- **FR-001**: The system shall run as a macOS menu bar application with search available from the menu bar. [INFERRED: HIGH] Source: `LocalLens/LocalLensApp.swift`, `specs/001-local-media-library/spec.md`
- **FR-002**: The system shall let users add, view, enable, disable, remove, and reauthorize watched folders. [INFERRED: HIGH] Source: `specs/001-local-media-library/spec.md`, folder access tests
- **FR-003**: The system shall persist authorized folder access across app restarts through app-scope bookmarks. [INFERRED: HIGH] Source: `project.yml`, `FolderAccess`, `specs/001-local-media-library/spec.md`
- **FR-004**: The system shall recursively discover supported media in watched folders while skipping unsupported, hidden, package, symlinked, or inaccessible files safely. [INFERRED: HIGH] Source: `MediaDiscoveryService`
- **FR-005**: The system shall maintain a local index of watched folders, assets, extraction records, searchable chunks, jobs, failures, settings, provider state, and generated content. [INFERRED: HIGH] Source: `MigrationV1`

## 2. Indexing and Extraction

- **FR-006**: The system shall index images with thumbnails, dimensions, local metadata, extracted/recognized text where available, generated descriptions when configured, and searchable chunks. [INFERRED: HIGH] Source: `IndexCoordinator.indexImageOrPDF`, image extractor tests, specs
- **FR-007**: The system shall index PDFs with thumbnails, page count, selectable text, recognized text from image pages where feasible, generated summaries when configured, and searchable chunks. [INFERRED: HIGH] Source: `IndexCoordinator.indexImageOrPDF`, `PDFExtractor`, PDF tests, specs
- **FR-008**: The system shall index Office documents only through Hermes Agent and produce safe summaries/searchable content when enabled and ready. [INFERRED: HIGH] Source: `IndexingPipelineRunner`, Office specs, Office routing tests
- **FR-009**: The system shall index audio with local duration metadata and transcript chunks when local transcription succeeds. [INFERRED: HIGH] Source: audio extractor and indexing tests
- **FR-010**: The system shall index video with local duration, bounded sampled scene metadata, thumbnails/keyframes, and transcript chunks when available. [INFERRED: HIGH] Source: video extractor and indexing tests
- **FR-011**: The system shall never present partial or cancelled extraction as a complete indexed record. [INFERRED: HIGH] Source: specs and indexing tests

## 3. Search and Result Actions

- **FR-012**: The system shall search across filenames, extracted text, PDF text, generated descriptions/summaries, transcripts, labels, and semantic metadata. [INFERRED: HIGH] Source: `SearchService.search`, `SearchableChunkBuilder`, generated content FTS tests
- **FR-013**: The system shall rank results and return thumbnails, file name, media type, folder/path context, match reasons, snippets, and page or timestamp hints when available. [INFERRED: HIGH] Source: `SearchRanker`, `SnippetBuilder`, search specs/tests
- **FR-014**: The system shall support preview, reveal in Finder, open, copy path, and copy snippet actions without modifying source files. [INFERRED: HIGH] Source: preview action tests and source mutation tests
- **FR-015**: The system shall support keyboard operation for primary search, result navigation, preview, reveal, pause/resume, and settings flows. [INFERRED: MEDIUM] Source: specs and UI tests

## 4. Indexing Control and Recovery

- **FR-016**: The system shall show indexing progress including queue size, running state, completed count, failed count, safe current label, and last indexed time where available. [INFERRED: HIGH] Source: `IndexingPipelineRunner`, progress store tests, specs
- **FR-017**: The system shall let users pause, resume, cancel, retry failed work, reindex one file, and reindex a watched folder. [INFERRED: HIGH] Source: specs and indexing control tests
- **FR-018**: The system shall persist queued/completed/failed job state and safely handle app relaunch. [INFERRED: HIGH] Source: `index_jobs` table, `IndexingPipelineRunner`, specs
- **FR-019**: The system shall record safe failure categories, retryability, stage, and recovery guidance. [INFERRED: HIGH] Source: `index_failures` table, `IndexingPipelineRunner`, diagnostics tests

## 5. Provider and AI Routing

- **FR-020**: The system shall let users select exactly one preferred AI provider for image descriptions and PDF summaries. [INFERRED: HIGH] Source: `BuildConfiguration.preferredAIProviderSettingKey`, provider settings specs/tests
- **FR-021**: The system shall use only the selected preferred provider for image long descriptions and PDF short summaries. [INFERRED: HIGH] Source: `ProviderRoutingService`, routing tests
- **FR-022**: The system shall not silently fall back to another provider when the preferred provider is missing, stale, blocked, or unavailable. [INFERRED: HIGH] Source: `ProviderRoutingService`
- **FR-023**: The system shall route Office summaries to Hermes Agent regardless of the preferred image/PDF provider. [INFERRED: HIGH] Source: `ProviderRoutingService`, Office routing tests
- **FR-024**: The system shall require a selected valid Hermes profile before Hermes-backed work. [INFERRED: HIGH] Source: `ProviderReadinessService.hermesProfileReadiness`
- **FR-025**: The system shall require selected valid Ollama and oMLX generation models before those providers can run descriptive enrichment. [INFERRED: HIGH] Source: `ProviderReadinessService.generationModelReadiness`
- **FR-026**: The system shall route all embedding requests to Ollama model `qwen3-embedding:4b`. [INFERRED: HIGH] Source: `BuildConfiguration`, `EmbeddingStageService`, routing tests
- **FR-027**: The system shall not route embeddings to the preferred descriptive provider, Hermes Agent, oMLX, or a remote provider. [INFERRED: HIGH] Source: `EmbeddingStageService`
- **FR-028**: The system shall block audio and video AI-provider prompting for new indexing work. [INFERRED: HIGH] Source: `ProviderRoutingService`, routing tests

## 6. Privacy, Security, and Diagnostics

- **FR-029**: The system shall preserve source files unchanged during discovery, indexing, preview, search, diagnostics, retry, rebuild, and cleanup. [INFERRED: HIGH] Source: specs, entitlements, source mutation tests
- **FR-030**: The system shall write only app-controlled local index data, cache data, settings, derived generated content, queue state, failures, and diagnostics. [INFERRED: HIGH] Source: specs, `LocalLensDatabase`, `project.yml`
- **FR-031**: The system shall store provider credentials through Keychain-backed credential handling. [INFERRED: HIGH] Source: `ProviderCredentialStore`, credential tests
- **FR-032**: The system shall redact diagnostics by default, omitting credentials, raw prompts, full paths, raw provider bodies, full extracted text, and full generated content. [INFERRED: HIGH] Source: `DiagnosticExporter`, `RedactionPolicy`, diagnostics tests
- **FR-033**: The system shall treat file-derived content and provider output as untrusted data. [INFERRED: HIGH] Source: prompt safety specs and Office prompt tests
- **FR-034**: The system shall gate remote-capable provider use through transport/privacy readiness instead of provider-row visibility alone. [INFERRED: HIGH] Source: `ProviderTransportPolicy`, provider specs/tests

## Business Rules and Invariants

| ID | Rule | Confidence | Source |
|----|------|------------|--------|
| BR-001 | Source files are read-only inputs and must not be mutated by LocalLens. | HIGH | Specs, entitlements, privacy tests |
| BR-002 | Watched folders define the authority boundary for discovery and indexing. | HIGH | Specs, folder access services |
| BR-003 | Unsupported, hidden, package, symlinked, or unauthorized files must not block indexing of other files. | HIGH | `MediaDiscoveryService` |
| BR-004 | Provider rows can be visible/enabled while provider-backed stages are still blocked by readiness. | HIGH | `ProviderRegistry`, `ProviderReadinessService` |
| BR-005 | Image/PDF descriptive enrichment uses at most one provider per attempt. | HIGH | `ProviderRoutingService` |
| BR-006 | Office document summaries use Hermes Agent only. | HIGH | `ProviderRoutingService`, Office specs |
| BR-007 | Embeddings use Ollama `qwen3-embedding:4b` only. | HIGH | `EmbeddingStageService`, BuildConfiguration |
| BR-008 | Audio and video must not trigger AI-provider prompting in new indexing work. | HIGH | `ProviderRoutingService` |
| BR-009 | Generated descriptions and summaries are local derived data and must be searchable by FTS. | HIGH | `generated_content_records`, generated content FTS tests |
| BR-010 | Diagnostics expose safe categories and readiness state, not sensitive raw content. | HIGH | Redaction and diagnostic tests |

## User Stories

### US-01: Add private library folders

As a Mac user, I want to add local folders to LocalLens so that my chosen media library can be indexed privately.

- Priority: P1
- Confidence: HIGH
- Independent test: Add a folder, relaunch, and confirm it remains listed or requests reauthorization.

### US-02: Search images and PDFs by content

As a user, I want screenshots, images, and PDFs to be searchable by text, content, and generated descriptions so that I can find files without remembering filenames.

- Priority: P1
- Confidence: HIGH
- Independent test: Index fixtures and search for OCR text, PDF text, and generated-description terms.

### US-03: Search all indexed media from the menu bar

As a user, I want to search across all indexed media from the menu bar so that retrieval is always available.

- Priority: P1
- Confidence: HIGH
- Independent test: Search a mixed library and inspect ranked results with match reasons.

### US-04: Configure provider behavior explicitly

As a user, I want to select the provider, model, or Hermes profile used for provider-backed work so that privacy, quality, and local/remote behavior are clear.

- Priority: P1
- Confidence: HIGH
- Independent test: Select providers/models/profiles, run indexing, and confirm route decisions.

### US-05: Include Office files safely

As a user, I want selected Office file types indexed through Hermes Agent so that documents are searchable without routing them to incompatible providers.

- Priority: P1
- Confidence: HIGH
- Independent test: Enable each Office type and confirm Hermes Agent-only routing with the matching skill directive.

### US-06: Control and recover indexing

As a user, I want to monitor, pause, cancel, retry, and rebuild indexing so that long-running local work remains trustworthy.

- Priority: P2
- Confidence: HIGH
- Independent test: Pause, resume, cancel, retry, and reindex while checking queue/failure state.

## User Flows

### Flow 1: First folder indexing

1. User opens LocalLens from the menu bar.
2. User adds a watched folder.
3. LocalLens stores bookmark and folder metadata.
4. LocalLens discovers supported files and queues index jobs.
5. The background runner processes jobs and writes extraction records, chunks, generated content, and failures as needed.
6. User searches after indexing completes or partially completes.

### Flow 2: Preferred provider image/PDF enrichment

1. User selects a preferred AI provider in Settings.
2. User satisfies provider readiness by selecting a Hermes profile or local model when needed.
3. Indexing reaches an image or PDF.
4. Provider routing checks stage, preferred provider, transport, credentials, and selected model/profile.
5. If allowed, one provider request is made for a bounded description or summary.
6. The bounded generated text is stored locally and added to searchable chunks.
7. If blocked, a safe failure or warning is recorded without fallback.

### Flow 3: Hermes Agent Office summary

1. User enables `.pptx`, `.docx`, or `.xlsx` indexing.
2. User selects a valid Hermes profile.
3. Discovery queues enabled Office files.
4. Indexing checks Hermes profile readiness before Office work.
5. Hermes Agent receives the matching document skill directive and bounded content request.
6. LocalLens stores safe summary metadata and searchable chunks.

### Flow 4: Search and act on a result

1. User enters a query in the popover.
2. SearchService loads FTS and semantic candidates.
3. SearchRanker scores and orders results.
4. SnippetBuilder builds safe context snippets.
5. User selects a result and previews, reveals, opens, copies path, or copies snippet.
6. The original file remains unchanged.

## Error Behaviors

| Condition | Behavior | Recovery |
|-----------|----------|----------|
| Folder access stale or denied | Mark access problem and avoid crashing | Reauthorize folder |
| File missing after discovery | Exclude or mark missing safely | Reindex folder or restore file |
| Corrupt/password-protected file | Record safe failure category | Fix file and retry |
| Preferred provider not selected | Block image/PDF enrichment | Select preferred provider |
| Hermes profile missing/stale | Block Hermes-backed work | Refresh and select valid profile |
| Ollama/oMLX model missing/stale | Block that provider's descriptive generation | Refresh and select valid model |
| Fixed embedding model missing | Mark embedding readiness unavailable | Install/expose `qwen3-embedding:4b` |
| Provider timeout or invalid output | Partial or failed provider-backed stage with safe failure | Retry after provider is healthy |
| User cancels indexing | Stop in-progress work and do not mark partial work complete | Resume or retry later |
| Local index corruption | Throw corruption error and use rebuild/delete-index recovery path | Rebuild local index |
