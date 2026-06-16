# Implementation Plan: AI Provider Indexing Preferences

**Branch**: `003-ai-provider-indexing` | **Date**: 2026-06-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-ai-provider-indexing/spec.md`

## Summary

Implement a single preferred AI provider setting for image long descriptions and PDF short summaries, route Office summaries exclusively through Hermes Agent, force all embeddings through Ollama model `qwen3-embedding:4b`, make generated descriptions and summaries searchable through the existing chunk and FTS pipeline, and remove provider-level enable toggles from Settings while keeping provider readiness gates for required Hermes profiles and Ollama/oMLX models.

The implementation extends existing provider settings, provider selection, prompt template, indexing coordinator, searchable chunk, FTS, diagnostics, and Settings UI paths. It preserves deterministic local extraction, non-destructive file handling, redacted diagnostics, and background indexing architecture.

## Technical Context

**Language/Version**: Swift 6+, Swift concurrency, Sendable-aware services

**Primary Dependencies**: SwiftUI Settings UI, AppKit where already used for macOS integration, Foundation URLSession provider clients, SQLite3 local persistence and FTS5, PDFKit/ImageIO/Vision-style existing extraction services, Hermes Agent-compatible profile routing, Ollama-compatible embeddings and chat endpoints, XCTest fixtures and URLProtocol-backed provider tests

**Storage**: Local Application Support SQLite database with WAL, `app_settings`, `provider_settings`, `provider_model_selections`, `hermes_profile_selection`, `extraction_records`, `searchable_chunks`, `searchable_chunks_fts`, `vector_embeddings`, and derived metadata tables. Add additive migration support for preferred provider selection, generated description/summary metadata, generated-text FTS columns or mapping, and fixed embedding route metadata where existing tables are insufficient.

**Testing**: XCTest unit/integration tests with injected provider clients, custom URLProtocol request-body assertions, deterministic image/PDF/Office/audio/video fixtures, Settings UI tests for provider controls, SQLite migration/FTS tests, privacy/security routing tests, and XCodeMCP build/test verification with xcodebuild fallback only if XCodeMCP gives non-actionable failures.

**Target Platform**: macOS 26.0+ menu bar app

**Project Type**: Native macOS SwiftUI/AppKit desktop menu bar app

**Performance Goals**: Provider-backed stages publish safe progress within 2 seconds of starting; generated text is bounded by `BuildConfiguration.maxPromptCharacters`; FTS search returns generated-description matches within the existing search result limit path; embedding batches stay bounded by chunk count and prompt-character caps; Settings remains responsive while providers refresh or indexing runs.

**Constraints**: Source files are read-only and never mutated; AI-provider prompting must be skipped for audio/video; exactly one preferred descriptive provider may be used per image/PDF enrichment attempt; remote-capable providers remain gated by transport/privacy readiness despite provider rows being always visible; Hermes profile is mandatory for Hermes-backed work; Ollama/oMLX generation model selection is mandatory before either can be the preferred descriptive provider; Ollama `qwen3-embedding:4b` readiness is mandatory for embedding attempts and separate from selected Ollama generation model.

**Scale/Scope**: Applies to existing LocalLens indexing of watched folders containing mixed image, PDF, Office, audio, and video assets; does not add new file mutation features, new remote-provider onboarding beyond existing transport/privacy gates, or new audio/video AI analysis.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **File-system authority**: PASS — reads only user-selected watched folders and existing eligible file types for derived indexing; writes only app-controlled settings, records, chunks, embeddings, failures, and diagnostics; source files remain unmodified.
- **Local-first AI**: PASS — Ollama is fixed for embeddings; local providers remain first-class; remote-capable preferred providers are only configuration targets until transport/privacy/credential readiness is satisfied.
- **Non-destructive media handling**: PASS — no source file rename, move, delete, rewrite, transcode, or repair is introduced.
- **Responsive architecture**: PASS — provider enrichment, embedding, extraction, SQLite writes, and indexing orchestration stay in cancellable background services/actors; Settings publishes lightweight readiness/progress state on MainActor.
- **Testable Swift design**: PASS — plan uses dependency-injected provider clients, repositories, prompt builders, routing services, and XCTest fixtures for routing, search, cancellation, and guardrails.
- **Privacy/secrets/transport**: PASS — credentials remain in Keychain; remote transports remain blocked or warning-gated by existing policy; diagnostics redact prompts, credentials, full paths, raw provider bodies, and full generated text by default.
- **Observability/recovery**: PASS — readiness warnings, failure categories, retry/ignore/reauthorize/rebuild actions, and provider route metadata are planned.
- **Performance bounds**: PASS — bounded prompts, bounded provider output, batched embeddings, 2-second progress publication, and safe skip/fail behavior for huge/corrupt files are planned.

## Project Structure

### Documentation (this feature)

```text
specs/003-ai-provider-indexing/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── provider-routing-contract.md
│   ├── generated-content-storage-contract.md
│   ├── settings-ui-contract.md
│   └── prompt-safety-contract.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
LocalLens/
├── AppShell/
│   ├── SettingsWindow.swift
│   └── SettingsWindowPresenter.swift
├── Diagnostics/
│   ├── DiagnosticExporter.swift
│   ├── PrivacyAudit.swift
│   └── RedactionPolicy.swift
├── Extractors/
│   ├── ImageExtractor.swift
│   ├── PDFExtractor.swift
│   └── OfficeDocumentExtractor.swift
├── Indexing/
│   ├── EmbeddingStageService.swift
│   ├── IndexCoordinator.swift
│   ├── IndexingPipelineRunner.swift
│   └── SearchableChunkBuilder.swift
├── Inference/
│   ├── OpenAICompatibleClient.swift
│   ├── PromptTemplates.swift
│   ├── ProviderRegistry.swift
│   └── ProviderSelectionService.swift
├── Search/
│   ├── SearchService.swift
│   ├── SearchRanker.swift
│   └── SnippetBuilder.swift
├── Storage/
│   ├── LocalLensDatabase.swift
│   ├── Migrations/MigrationV1.swift
│   ├── Models/DomainEnums.swift
│   ├── Models/LocalLensModels.swift
│   └── Repositories/
│       ├── RepositoryProtocols.swift
│       └── SQLiteRepositories.swift
└── Support/
    └── DependencyContainer.swift

LocalLensTests/
├── IndexingTests/
├── InferenceTests/
├── PrivacySecurityTests/
├── SearchTests/
├── StorageTests/
├── Support/
└── Fixtures/

LocalLensUITests/
├── SettingsProviderModelSelectionUITests.swift
├── SettingsHermesProfileSelectionUITests.swift
└── SettingsUITests.swift
```

**Structure Decision**: Keep the feature in the existing single-target LocalLens app architecture. Extend current provider selection, prompt, indexing, storage, search, diagnostics, and Settings files instead of introducing a new module. Add focused XCTest files under existing test directories and extend UI tests that already cover provider model/profile selection.

## Phase 0: Research Decisions

See [research.md](./research.md) for the resolved decisions. Highlights:

1. Use one persisted preferred descriptive provider in local settings and validate readiness at stage start.
2. Add a provider-enrichment stage for images/PDFs before chunk building so generated description/summary text is persisted and chunked like other derived text.
3. Keep Office summaries on the existing Hermes Agent path, but tighten prompt output to short summaries and make storage/chunking consistent with generated image/PDF text.
4. Replace heuristic embedding-provider selection with a fixed Ollama route and model `qwen3-embedding:4b`.
5. Remove audio/video embedding and provider calls from new indexing work to satisfy the no AI-provider-prompting rule.
6. Keep remote privacy gates independent from provider-row visibility.

## Phase 1: Design Output

- [data-model.md](./data-model.md): preferred provider, readiness state, embedding route, generated content, chunks, failures, and state transitions.
- [contracts/provider-routing-contract.md](./contracts/provider-routing-contract.md): per-media provider routing matrix and readiness outcomes.
- [contracts/generated-content-storage-contract.md](./contracts/generated-content-storage-contract.md): local persistence and FTS contract for generated descriptions/summaries.
- [contracts/settings-ui-contract.md](./contracts/settings-ui-contract.md): Settings UI behavior after removing provider enable toggles.
- [contracts/prompt-safety-contract.md](./contracts/prompt-safety-contract.md): prompt and output safety requirements for image/PDF/Office summarization.
- [quickstart.md](./quickstart.md): manual QA and verification steps for planning handoff.

## Post-Design Constitution Check

- **File-system authority**: PASS — design artifacts keep all writes to LocalLens-owned storage and all source file operations read-only.
- **Local-first AI**: PASS — fixed Ollama embeddings and provider readiness contracts keep local-first behavior while preserving explicit privacy gates for remote-capable preferred providers.
- **Non-destructive media handling**: PASS — contracts and data model include no source-file mutation paths.
- **Responsive architecture**: PASS — indexing/enrichment services remain background/cancellable and Settings stays MainActor-only for lightweight state.
- **Testable Swift design**: PASS — contracts identify injectable provider clients, repositories, prompt templates, and fixtures for deterministic tests.
- **Privacy/secrets/transport**: PASS — prompt safety and diagnostics contracts require Keychain, redaction, bounded outputs, and transport guardrails.
- **Observability/recovery**: PASS — data model and contracts include readiness warnings, failure categories, route metadata, and recovery actions.
- **Performance bounds**: PASS — output caps, prompt caps, stage progress, and skip/fail behavior are explicit.

## Complexity Tracking

No constitution violations or complexity exceptions are introduced.
