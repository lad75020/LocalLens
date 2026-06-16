# Feature Specification: AI Provider Indexing Preferences

**Feature Branch**: `003-ai-provider-indexing`

**Created**: 2026-06-16

**Status**: Draft

**Input**: User description: "In Settings, allow the user to set their preferred AI provider. Only one AI provider can be inferred at any time by the indexing process. For embeddings, always prompt AI provider OLLAMA with model \"qwen3-embedding:4b\". When indexing image files, always prompt the user preferred AI provider to get a long description of image content. When indexing PDF files, always prompt the user preferred AI provider to get a short summary of PDF content. When indexing office files, always prompt Hermes agent AI provider to get a short summary of office file content. Persist description or summary in DB, and make them searchable by FTS. Never prompt AI providers to index video or audio files. In settings, remove the AI provider enable toggle. They are always all enabled. Selecting a profile for Hermes agent or a model for ollama and omlx providers is mandatory."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose one preferred provider for descriptive indexing (Priority: P1)

A user opens Settings and selects the AI provider LocalLens should use for image descriptions and PDF summaries so indexing uses exactly the provider they intend.

**Why this priority**: Provider choice controls privacy, quality, cost, and latency for content sent outside deterministic local extractors. The user must have a single, visible preference before provider-backed image or PDF enrichment starts.

**Independent Test**: Can be fully tested by selecting each available provider in Settings, indexing one image and one PDF, and confirming only the selected provider is asked for the descriptive enrichment stage while all other providers are not contacted for that stage.

**Acceptance Scenarios**:

1. **Given** providers are visible in Settings, **When** the user selects a preferred AI provider, **Then** LocalLens persists that provider as the single descriptive-indexing preference.
2. **Given** a preferred provider is selected and ready, **When** LocalLens indexes an image, **Then** it requests one long image-content description only from that provider.
3. **Given** a preferred provider is selected and ready, **When** LocalLens indexes a PDF, **Then** it requests one short PDF-content summary only from that provider.
4. **Given** the preferred provider is missing required setup, stale, blocked by transport policy, or otherwise unavailable, **When** image or PDF provider enrichment would start, **Then** LocalLens pauses or fails that enrichment with a safe, actionable message instead of silently falling back to another provider.

---

### User Story 2 - Enforce mandatory provider readiness without enable toggles (Priority: P1)

A user configures required provider choices in Settings without managing enable switches because providers are always available as configuration targets, while readiness is based on required profile or model selections.

**Why this priority**: Removing provider enable toggles simplifies Settings and prevents ambiguous states where a provider exists but cannot be used. Mandatory profile/model selections make the indexing route explicit and testable.

**Independent Test**: Can be fully tested by opening Settings, verifying provider enable toggles are absent, confirming every provider appears as enabled/available, and checking that Hermes Agent requires a selected profile while Ollama and oMLX require selected models before provider-backed work can start.

**Acceptance Scenarios**:

1. **Given** the user opens AI Provider Settings, **When** provider rows are displayed, **Then** no provider-level "Enabled" toggle is shown.
2. **Given** Hermes Agent is present, **When** no Hermes profile is selected or the selected profile becomes unavailable, **Then** Hermes Agent-backed indexing is marked not ready until a valid profile is selected.
3. **Given** Ollama is present, **When** no Ollama model is selected or the selected model becomes unavailable, **Then** Ollama-backed indexing is marked not ready until a valid model is selected.
4. **Given** oMLX is present, **When** no oMLX model is selected or the selected model becomes unavailable, **Then** oMLX-backed indexing is marked not ready until a valid model is selected.
5. **Given** a remote-capable provider is selected as preferred, **When** it would receive file content or derived text for the first time, **Then** LocalLens shows clear privacy and transport copy before any such data is sent.

---

### User Story 3 - Use fixed Ollama embeddings while making summaries searchable (Priority: P2)

A user searches their indexed library and finds files by provider-generated image descriptions, PDF summaries, and Office summaries, while embeddings are always produced by the fixed Ollama embedding model.

**Why this priority**: Search quality depends on newly generated descriptions and summaries being stored and searchable, while embedding consistency requires one stable embedding route independent of the user's preferred descriptive provider.

**Independent Test**: Can be fully tested by indexing an image, PDF, and Office document with distinctive generated text, then searching for terms that appear only in those descriptions or summaries and confirming matching results are returned.

**Acceptance Scenarios**:

1. **Given** any searchable chunk needs embeddings, **When** LocalLens requests embeddings, **Then** it always requests them from Ollama with model `qwen3-embedding:4b`.
2. **Given** an image description is generated, **When** indexing completes, **Then** the description is stored locally and can be found through full-text search.
3. **Given** a PDF summary is generated, **When** indexing completes, **Then** the summary is stored locally and can be found through full-text search.
4. **Given** an Office summary is generated, **When** indexing completes, **Then** the summary is stored locally and can be found through full-text search.

---

### User Story 4 - Exclude audio and video from AI-provider prompting (Priority: P2)

A user indexes folders that contain audio or video files and trusts that LocalLens will not prompt AI providers to analyze those file types.

**Why this priority**: Audio and video can contain highly sensitive content and large payloads. The requested feature explicitly excludes AI-provider prompting for these file types.

**Independent Test**: Can be fully tested by indexing audio and video fixtures with provider request logging enabled and confirming no AI-provider request is made for audio or video indexing stages.

**Acceptance Scenarios**:

1. **Given** a watched folder contains an audio file, **When** LocalLens indexes the folder, **Then** no AI provider is prompted to index, transcribe, summarize, describe, embed, or classify that audio file.
2. **Given** a watched folder contains a video file, **When** LocalLens indexes the folder, **Then** no AI provider is prompted to index, transcribe, summarize, describe, embed, or classify that video file.
3. **Given** existing audio or video indexing metadata exists from earlier runs, **When** this feature is active, **Then** new indexing work does not create new AI-provider requests for audio or video files.

---

### Edge Cases

- The preferred AI provider is deleted, renamed, unreachable, transport-blocked, or fails while an indexing batch is in progress.
- Hermes Agent reports no profiles, a selected profile disappears, or credentials are missing when Hermes Agent is selected or required for Office files.
- Ollama is reachable but does not report `qwen3-embedding:4b`, or reports the model but embedding generation fails.
- Ollama or oMLX reports no selectable generation models even though provider rows remain visible and always enabled.
- A remote-capable preferred provider is selected before the user has acknowledged which image/PDF data classes may leave the Mac.
- A mixed folder contains images, PDFs, Office documents, audio, and video in the same indexing batch.
- Provider-generated text contains prompt-injection instructions, unsafe content, very long output, invalid formatting, or empty content.
- A file is moved, deleted, permission-denied, corrupted, password-protected, or too large between discovery and enrichment.
- The user changes the preferred provider while indexing is already running.
- The local database already contains older descriptions, summaries, chunks, or embeddings generated under a different provider route.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to select exactly one preferred AI provider in Settings for image and PDF descriptive enrichment.
- **FR-002**: The system MUST persist the preferred AI provider selection across app restarts.
- **FR-003**: The indexing process MUST infer at most one descriptive AI provider for any single image or PDF enrichment stage.
- **FR-004**: The indexing process MUST NOT call multiple descriptive AI providers for the same image or PDF enrichment stage unless the user explicitly retries after changing the preferred provider.
- **FR-005**: When indexing an image file, the system MUST request a long description of image content from the user's preferred AI provider.
- **FR-006**: When indexing a PDF file, the system MUST request a short summary of PDF content from the user's preferred AI provider.
- **FR-007**: When indexing an Office file, the system MUST request a short summary of Office file content from Hermes Agent, regardless of the user's preferred image/PDF provider.
- **FR-008**: The system MUST NOT prompt any AI provider to index, transcribe, summarize, describe, classify, embed, or otherwise analyze audio files.
- **FR-009**: The system MUST NOT prompt any AI provider to index, transcribe, summarize, describe, classify, embed, or otherwise analyze video files.
- **FR-010**: For embeddings, the system MUST always request embeddings from Ollama with model `qwen3-embedding:4b`.
- **FR-011**: The system MUST NOT use the user's preferred descriptive provider, Hermes Agent, oMLX, or any remote provider for embeddings.
- **FR-012**: The system MUST persist generated image descriptions, PDF summaries, and Office summaries in local storage associated with the indexed asset and the provider route used.
- **FR-013**: Persisted image descriptions, PDF summaries, and Office summaries MUST be included in full-text search so users can find assets by terms contained only in those generated texts.
- **FR-014**: Search results matching generated descriptions or summaries MUST show a safe snippet or match reason that makes the generated-text match understandable without exposing more content than necessary.
- **FR-015**: Settings MUST remove provider-level enable toggles from the AI Providers area.
- **FR-016**: Provider rows MUST remain visible as always-enabled configuration targets, with readiness and transport state replacing enable/disable state.
- **FR-017**: Selecting a Hermes Agent profile MUST be mandatory before Hermes Agent can be used for preferred-provider image/PDF enrichment or required Office summarization.
- **FR-018**: Selecting a model for Ollama MUST be mandatory before Ollama can be used for preferred-provider image/PDF enrichment.
- **FR-019**: Selecting a model for oMLX MUST be mandatory before oMLX can be used for preferred-provider image/PDF enrichment.
- **FR-020**: The fixed Ollama embedding model readiness MUST be validated separately from the user-selected Ollama generation model.
- **FR-021**: If a required provider profile, generation model, or embedding model is missing, stale, or unavailable, the system MUST block only the affected provider-backed stage and record a safe retryable failure or readiness warning.
- **FR-022**: Provider prompts for image descriptions, PDF summaries, and Office summaries MUST treat file-derived content as untrusted data and MUST instruct the provider not to follow instructions embedded in file content.
- **FR-023**: Provider prompts MUST request bounded, search-oriented outputs and MUST avoid requesting raw full file content reproduction.
- **FR-024**: Provider output MUST be bounded, sanitized for display, and safe to store before it is persisted or included in searchable text.
- **FR-025**: Changing the preferred AI provider in Settings MUST affect new provider-backed indexing work and MUST NOT silently rewrite existing generated descriptions or summaries.
- **FR-026**: Rebuild or reindex flows MUST make it clear when previously generated descriptions, summaries, chunks, or embeddings may be regenerated under the current provider preferences.
- **FR-027**: Diagnostics MUST report provider routing, readiness, skipped stages, safe failure categories, and retryability without logging raw prompts, credentials, full paths, full provider outputs, or full extracted file text by default.

### Constitutional Requirements *(mandatory for file-system or AI features)*

- **CA-001 File Authority**: This feature reads user-selected watched folders and indexed file types already eligible for LocalLens indexing. It reads image, PDF, and Office files only to create derived descriptions or summaries and writes only LocalLens-controlled settings, provider readiness state, derived description/summary records, searchable chunks, embeddings for eligible chunks, job state, safe failures, and diagnostics. It MUST NOT write, rename, move, delete, repair, convert in place, or otherwise modify source files.
- **CA-002 Local/Remote AI**: LocalLens remains local-first. Ollama is the only embedding provider and uses `qwen3-embedding:4b`. Image and PDF descriptive enrichment uses the single user-preferred provider, which may be local or remote-capable only after the user selects it and sees clear privacy/transport labeling. Office summarization uses Hermes Agent only. Provider rows being always enabled means they are always visible/configurable; it does not bypass remote-provider privacy copy, transport blocking, credentials, or readiness gates.
- **CA-003 Privacy & Retention**: LocalLens stores preferred provider selection, selected Hermes profile, selected Ollama and oMLX models, generated image descriptions, generated PDF summaries, generated Office summaries, searchable chunks, embedding model identifiers, provider route metadata, and safe failure state in local app-controlled storage. Existing delete-index and rebuild-index controls govern removal or regeneration of derived descriptions, summaries, chunks, and embeddings.
- **CA-004 Non-Destructive Guarantee**: Source image, PDF, Office, audio, and video files remain unmodified during provider selection, indexing, enrichment, embedding, retry, cancellation, search, diagnostics, and rebuild flows.
- **CA-005 Failure & Recovery**: The system must provide safe behavior for denied folder access, stale authorization, missing files, corrupted or password-protected PDFs and Office documents, provider unavailability, missing profile/model selection, missing Ollama embedding model, transport blocking, timeout, invalid provider output, cancellation, app restart, and local index corruption. Recovery actions include choose provider, choose profile/model, retry, ignore, reauthorize, cancel, reindex, delete local index, or rebuild index as applicable.
- **CA-006 Performance Bounds**: Provider-backed enrichment and embedding must run as bounded background work, must not block Settings or search interactions, and must publish safe progress within 2 seconds of a provider-backed stage starting. Very large files may be partially summarized, skipped, or failed safely rather than exhausting memory or sending unbounded prompts.
- **CA-007 Observability**: Settings, progress, diagnostics, and failure dashboards must show preferred provider, profile/model readiness, fixed embedding-model readiness, skipped audio/video AI-provider stages, provider route used for generated text, failure category, and retryability without exposing raw file contents, raw prompts, credentials, full paths, full provider responses, or full generated descriptions/summaries by default.

### Key Entities *(include if feature involves data)*

- **Preferred AI Provider Selection**: The single provider chosen by the user for image long descriptions and PDF short summaries, including readiness and last validation state.
- **Provider Readiness State**: Per-provider state that replaces enable toggles, including transport, credentials, profile/model selection, selected value availability, and safe error text.
- **Hermes Profile Selection**: Required selected Hermes Agent profile used for Hermes-backed image/PDF enrichment when Hermes is preferred and always used for Office summaries.
- **Provider Model Selection**: Required selected generation model for Ollama and oMLX when either provider is used for descriptive enrichment.
- **Embedding Route**: Fixed embedding configuration that always targets Ollama model `qwen3-embedding:4b` and records readiness separately from generation-model settings.
- **Generated Description/Summary**: Local derived text for an asset, including asset reference, media kind, provider route, profile/model identifier where applicable, output kind, bounded text, status, and timestamps.
- **Searchable Generated Chunk**: Full-text searchable chunk created from generated descriptions or summaries, linked to the asset and extraction record.
- **Provider Routing Failure**: Safe failure record describing missing configuration, blocked transport, provider error, invalid output, timeout, cancellation, or skipped ineligible media type.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can select or change the preferred AI provider from Settings in under 60 seconds.
- **SC-002**: 100% of image description enrichment requests are sent only to the currently preferred ready provider and produce at most one provider request per image enrichment attempt.
- **SC-003**: 100% of PDF summary enrichment requests are sent only to the currently preferred ready provider and produce at most one provider request per PDF enrichment attempt.
- **SC-004**: 100% of Office summary requests are routed to Hermes Agent and require a valid selected Hermes profile before starting.
- **SC-005**: 100% of embedding requests are routed to Ollama with model `qwen3-embedding:4b`.
- **SC-006**: 0 AI-provider requests are made for audio or video files during new indexing runs.
- **SC-007**: Generated image descriptions, PDF summaries, and Office summaries are searchable by full-text search immediately after successful indexing.
- **SC-008**: Settings shows no provider-level enable toggle while still showing provider readiness, profile/model requirements, and safe action guidance for every provider.
- **SC-009**: If required profile/model/embedding readiness is missing, users see a readiness warning before new affected provider-backed work starts.
- **SC-010**: Provider routing failures appear in diagnostics or the failure dashboard with safe categories and recovery actions, without exposing raw prompts, credentials, full paths, or full file-derived content.

## Assumptions

- The preferred AI provider applies to image long descriptions and PDF short summaries only; Office summaries continue to use Hermes Agent, and embeddings continue to use the fixed Ollama embedding model.
- "Providers are always enabled" means provider rows are always visible and configurable, not that remote content transmission bypasses privacy, transport, credentials, profile/model, or first-use readiness gates.
- Hermes Agent profile selection, Ollama model selection, and oMLX model selection are stored locally and must be valid before that provider can run provider-backed enrichment.
- The Ollama model selected for descriptive enrichment can differ from the fixed Ollama embedding model `qwen3-embedding:4b`; both readiness states are visible when relevant.
- Existing deterministic local extraction such as thumbnails, selectable PDF text extraction, local OCR, or metadata extraction may still run for supported files, but AI-provider prompting follows the routing rules in this specification.
- Existing delete-index, rebuild-index, retry, cancel, and diagnostics flows remain the governing user controls for derived local data and failures.
