# Data and Interfaces Reference

This file documents LocalLens internal data and service interfaces. It is not an HTTP API reference. No HTTP API contract files were found for this desktop application.

## Runtime Entry Points

| Surface | Source | Purpose |
|---------|--------|---------|
| `LocalLensApp` | `LocalLens/LocalLensApp.swift` | App entry point, creates menu bar extra, app commands, dependency container |
| `DependencyContainer` | `LocalLens/Support/DependencyContainer.swift` | Composes database, repositories, services, actors, view models, diagnostics, settings |
| `MenuBarRootView` | `LocalLens/AppShell/MenuBarRootView.swift` | Menu bar root UI |
| `SettingsWindow` | `LocalLens/AppShell/SettingsWindow.swift` | Settings UI for folders, indexing, providers, privacy, diagnostics |
| `SearchPopoverView` | `LocalLens/AppShell/SearchPopoverView.swift` | Search UI and result list |

## Core Domain Entities

| Entity | Source | Purpose |
|--------|--------|---------|
| Watched folder | `LocalLensModels.swift`, `watched_folders` | User-authorized folder and bookmark state |
| Media asset | `LocalLensModels.swift`, `media_assets` | Discovered local file with type, identity, relative path, status, metadata |
| Extraction record | `LocalLensModels.swift`, `extraction_records` | Extraction or provider stage output/status for an asset |
| Searchable chunk | `LocalLensModels.swift`, `searchable_chunks` | Text-like searchable unit with optional page/timestamp/embedding |
| Vector embedding | `vector_embeddings` | Binary vector data linked to a chunk |
| Index job | `LocalLensModels.swift`, `index_jobs` | Queued/running/completed/failed indexing work |
| Index failure | `LocalLensModels.swift`, `index_failures` | Safe failure category, retryability, stage, and message |
| Provider setting | `ProviderSetting`, `provider_settings` | Provider endpoint, transport, credential, model and health state |
| Provider model selection | `provider_model_selections` | Selected and available local generation models |
| Hermes profile selection | `hermes_profile_selection` | Selected and available Hermes Agent profiles |
| Office preferences | `office_preferences` | Per-file-type Office indexing toggles |
| Generated content record | `generated_content_records` | Bounded generated descriptions/summaries and provider route metadata |

## SQLite Tables

`MigrationV1` creates these tables and indexes:

- `schema_migrations`
- `watched_folders`
- `media_assets`
- `extraction_records`
- `searchable_chunks`
- `searchable_chunks_fts` using FTS5
- `vector_embeddings`
- `index_jobs`
- `index_failures`
- `provider_settings`
- `office_preferences`
- `provider_model_selections`
- `hermes_profile_selection`
- `office_extraction_metadata`
- `generated_content_records`
- `app_settings`

The database runs with `PRAGMA journal_mode=WAL`.

## Provider Interfaces

### Provider registry

`ProviderRegistry.defaultProviders()` defines visible provider rows:

| Provider id | Display name | Default URL | Automatic default |
|-------------|--------------|-------------|-------------------|
| `omlx` | oMLX | `http://localhost:17998/v1` | true |
| `ollama` | Ollama | `http://localhost:11434/v1` | true |
| `hermes-agent` | Hermes Agent | `http://localhost:8642/v1` | false |
| `custom` | Custom Remote | `https://example.invalid/v1` | false |

Provider rows are normalized visible/enabled by `ProviderRegistry.normalizedVisibleProvider`. Actual use is controlled by readiness and routing.

### Provider routing stages

`ProviderRoutingStage` defines these stages:

- `imageDescription`
- `pdfSummary`
- `officeSummary`
- `embeddings`
- `audio`
- `video`

### Route decisions

| Stage | Route behavior |
|-------|----------------|
| `imageDescription` | Use the selected preferred provider when ready |
| `pdfSummary` | Use the selected preferred provider when ready |
| `officeSummary` | Use Hermes Agent with selected Hermes profile |
| `embeddings` | Use Ollama model `qwen3-embedding:4b` |
| `audio` | Block provider prompting |
| `video` | Block provider prompting |

### Readiness states

Provider readiness considers:

- Transport state
- Credential state
- Selected generation model for Ollama and oMLX
- Selected Hermes profile for Hermes Agent
- Fixed Ollama embedding model availability
- Safe user-facing error text

## Indexing Interfaces

### IndexingPipelineRunner

`IndexingPipelineRunner` drains queued jobs in the background. It:

1. Publishes queue snapshots.
2. Marks jobs running, completed, cancelled, or failed.
3. Resolves security-scoped folder access.
4. Loads providers from storage.
5. Dispatches assets by media type.
6. Records safe failures and retryability.

### Media type dispatch

| Media type | Coordinator path |
|------------|------------------|
| Image | `indexImageOrPDF` |
| PDF | `indexImageOrPDF` |
| Office | `indexOfficeDocument` after Hermes profile readiness check |
| Audio | `indexAudioVideo` |
| Video | `indexAudioVideo` |

### Media discovery

`MediaDiscoveryService.discover` enumerates files with resource keys, skips hidden/package/symlinked directories, resolves supported media types, applies Office policy, records file identity, and creates `IndexJob` entries.

## Search Interfaces

### SearchService

`SearchService.search` combines:

- Watched folder state
- FTS search in `searchable_chunks_fts`
- Searchable chunks
- Semantic vector candidates when embeddings are available
- Asset matching and filtering
- Lexical scoring and result ranking
- Snippet construction and match reasons

### Search result actions

Result actions are composed through `ResultActionService` and include:

- Quick Look preview
- Reveal in Finder
- Open with default behavior
- Copy path
- Copy snippet

Actions must preserve source file bytes.

## Diagnostic Interfaces

| Component | Purpose |
|-----------|---------|
| `PrivacyAudit` | Reports whether source mutation is allowed, provider defaults are private, and diagnostics are redacted |
| `RedactionPolicy` | Redacts credentials and provider bodies |
| `DiagnosticExporter` | Produces safe diagnostic export structures for counts, provider health, Office preferences, provider model/profile selection, and failure categories |

## Contract Boundaries

- Public user-facing behavior is documented in `user-guide.md`.
- Developer-facing architecture and operations are documented in `architecture.md`, `developer-guide.md`, and `deployment-guide.md`.
- No HTTP API endpoint contract exists in the repository evidence. If future LocalLens exposes HTTP, XPC, CLI, or plugin APIs, add contract files first, then generate a dedicated API reference from those contracts.
