# Evidence Packet: LocalLens

## Scope

This evidence packet supports the generated LocalLens application documentation set under `.sdd/docs/`.

## Codebase-memory baseline

- Project root: `/Volumes/WDBlack4TB/Code/LocalLens`
- codebase-memory project id: `Volumes-WDBlack4TB-Code-LocalLens`
- Index status: `ready`
- Graph size: 2311 nodes and 5351 edges
- Graph schema highlights: `Class`, `Method`, `Function`, `Interface`, `File`, `Folder`, `Module`, `Variable`, `Section`
- Relationship highlights: `DEFINES`, `DEFINES_METHOD`, `CALLS`, `USAGE`, `INHERITS`, `CONTAINS_FILE`, `CONTAINS_FOLDER`

## Codebase-memory tools used

- `list_projects` to locate the LocalLens graph.
- `index_status` to verify the graph was ready before writing documentation.
- `get_graph_schema` and `get_architecture` for the structural baseline.
- `search_graph` for app entry points, settings, indexing, search, provider routing, diagnostics, storage, tests, and extractor surfaces.
- `query_graph` for the indexed source file inventory.
- `trace_path` for `IndexCoordinator.indexImageOrPDF`, `IndexCoordinator.indexAudioVideo`, and `SearchService.search`.
- `get_code_snippet` for `LocalLensApp`, `DependencyContainer`, `BuildConfiguration`, `LocalLensDatabase`, `ProviderRegistry`, `ProviderRoutingService`, `ProviderReadinessService`, `EmbeddingStageService`, `IndexingPipelineRunner`, `MediaDiscoveryService`, and `ProviderSetting`.

## Source and spec files read directly

- `AGENTS.md`
- `project.yml`
- `LocalLens.xcodeproj/xcshareddata/xcschemes/LocalLens.xcscheme`
- `LocalLens/Storage/Migrations/MigrationV1.swift`
- `specs/001-local-media-library/spec.md`
- `specs/002-office-provider-settings/spec.md`
- `specs/003-ai-provider-indexing/spec.md`
- `specs/003-ai-provider-indexing/plan.md`

## Application facts established from evidence

- LocalLens is a native macOS 26.0+ SwiftUI menu bar application.
- The app entry point is `LocalLensApp`, which creates a `MenuBarExtra` named `LocalLens` and injects `DependencyContainer` into `MenuBarRootView`.
- `DependencyContainer` wires the SQLite database, repositories, extraction services, provider services, indexing queue, search services, folder access services, preview actions, diagnostics, privacy audit, and settings window presenter.
- Local data is stored under the user's Application Support `LocalLens` directory through `LocalLensDatabase.defaultApplicationSupportURL()`.
- The database uses SQLite with WAL and includes tables for watched folders, media assets, extraction records, searchable chunks, FTS5, vector embeddings, index jobs, failures, provider settings, Office preferences, model/profile selections, generated content records, and app settings.
- The project uses Swift 6 with complete strict concurrency in `project.yml`.
- The app target is sandboxed, uses read-only user-selected file access, app-scope bookmarks, and network client entitlement.
- Supported source domains include images, PDFs, Office files, audio, and video, with source file mutation explicitly forbidden by requirements and tests.
- Search combines indexed filenames, extracted text, generated text, transcript text, labels, snippets, semantic vector candidates, and ranked match reasons.
- Provider defaults are oMLX, Ollama, Hermes Agent, and a custom remote provider. Provider rows are normalized visible/enabled, while readiness gates actual use.
- Default provider endpoint constants are `http://localhost:17998/v1` for oMLX, `http://localhost:11434/v1` for Ollama, and `http://localhost:8642/v1` for Hermes Agent.
- Image descriptions and PDF summaries use the single user-preferred ready provider.
- Office summaries always route to Hermes Agent and require a valid selected Hermes profile.
- Embeddings always use Ollama model `qwen3-embedding:4b` when available.
- Audio and video stages are explicitly blocked from AI-provider prompting by `ProviderRoutingService`.
- Build/test information is present in `project.yml` and the shared `LocalLens` Xcode scheme. No Dockerfile or CI deployment pipeline was found during this evidence pass.

## Evidence gaps and boundaries

- No HTTP API route graph or API contract file named `api-contracts.*` was found. The documentation therefore does not create `.sdd/docs/api-reference.md`; LocalLens is documented as a desktop app with internal Swift services and feature contracts.
- No server health endpoints were found. Deployment health checks are documented as build, launch, UI, indexing, provider readiness, and local storage checks.
- No automated release pipeline or notarization script was found. Deployment documentation describes verified local build/test/archive paths and marks notarization/distribution automation as repository-undefined.
- Final repository verification showed only the generated `.sdd/docs/` documentation files as untracked changes from this workflow.
