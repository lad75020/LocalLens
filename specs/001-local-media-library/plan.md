# Implementation Plan: LocalLens Private Media Library MVP

**Branch**: `001-local-media-library` | **Date**: 2026-06-15 | **Spec**: `specs/001-local-media-library/spec.md`

**Input**: Feature specification from `/specs/001-local-media-library/spec.md`

## Summary

Build LocalLens as a native macOS 26 SwiftUI menu bar application that indexes user-authorized local media folders and enables private search across screenshots, images, PDFs, audio, and video. The MVP uses an Xcode project named `LocalLens.xcodeproj`, Swift 6.3 strict-concurrency architecture, security-scoped bookmarks, cancellable background indexing actors, local SQLite/FTS storage, derived thumbnails, Apple framework extractors, and pluggable local/remote AI inference adapters. Local AI is the default; loopback providers are supported for oMLX, Ollama, and Hermes Agent, while any non-loopback remote endpoint is disabled by default and requires explicit opt-in plus transport validation.

## Technical Context

**Language/Version**: Swift 6.3.2 with strict concurrency enabled; SwiftUI and AppKit on macOS 26.0+; verified host tooling is Xcode 26.5 on macOS 26.5.1.

**Primary Dependencies**: SwiftUI `MenuBarExtra`, AppKit bridges for panels and Finder/Quick Look actions, UniformTypeIdentifiers, Vision, PDFKit, AVFoundation, QuickLookUI, OSLog, Security/Keychain, SQLite FTS5 via GRDB.swift or a thin SQLite adapter, and local OpenAI-compatible inference clients for oMLX/Ollama/Hermes Agent. No Electron, no web wrapper.

**Storage**: Local app-controlled Application Support directory with SQLite metadata/search database, FTS5 text index, vector-embedding table or sidecar vector store, thumbnail cache, derived transcript/keyframe cache, security-scoped bookmark store, redacted diagnostics, and provider settings. Secrets/API keys are stored in Keychain only.

**Testing**: XCTest unit tests, integration tests with fixture folders, and UI smoke tests for menu bar/search/settings flows. Mandatory tests cover bookmark restoration, recursive discovery, indexing queue state, extractor success/failure, search ranking, cancellation, provider guardrails, diagnostics redaction, non-destructive source-file checks, and 10k-asset search performance fixtures.

**Target Platform**: macOS 26.0+ native menu bar app. Initial distribution targets direct download/TestFlight-style local builds; Mac App Store sandbox compatibility remains a design constraint.

**Project Type**: Native macOS SwiftUI/AppKit desktop/menu bar app generated as `LocalLens.xcodeproj` with app, unit test, and UI test targets.

**Performance Goals**:
- Search over an already-indexed 10,000-asset library returns first usable results in under 500 ms on target Apple Silicon hardware.
- Menu bar popover and Settings remain responsive during recursive discovery, OCR, transcription, embeddings, and video sampling.
- Thumbnail generation is bounded to a maximum display size and avoids retaining full-size media in memory.
- Video indexing samples bounded representative frames rather than decoding full frame-by-frame content.

**Constraints**:
- Source media files are read-only for MVP: no rename, move, write, delete, transcode, metadata edit, or cleanup operation.
- Local AI is the default path; remote/non-loopback inference is opt-in, disabled by default, transport-guarded, and clearly labeled.
- Plain HTTP is allowed only for loopback/local endpoints (`localhost`, `127.0.0.1`, `::1`). Non-loopback endpoints require HTTPS unless the user explicitly enables an unsafe-development override.
- Long-running work is performed by services/actors outside `MainActor`; UI receives lightweight progress snapshots only.
- The invalid input form `http://localhost://17998` is normalized in the plan to `http://localhost:17998`.

**Scale/Scope**:
- MVP supports PNG, JPEG, HEIC, TIFF, WebP, PDF, MP3, M4A, WAV, AAC, MP4, MOV, and M4V discovery.
- Primary QA fixture: at least 10 images/screenshots, 3 PDFs, 3 audio files, and 3 videos.
- Performance QA fixture: synthetic 10,000-asset indexed library plus a 1,000-file mixed-media indexing run.
- Initial AI provider list: oMLX at `http://localhost:17998/v1`, Ollama at `http://localhost:11434/v1`, Hermes Agent at `http://localhost:8642/v1`, and a disabled custom remote provider slot.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **File-system authority**: PASS — LocalLens reads only user-selected watched folders and derived local app storage. MVP source media operations are read-only; denied, moved, missing, stale, external, and permission-revoked paths are tracked as recoverable authorization or availability states.
- **Local-first AI**: PASS — Apple framework extractors and loopback providers are the baseline. oMLX, Ollama, and Hermes Agent endpoints are local loopback defaults. Non-loopback remote providers require explicit user opt-in, HTTPS transport, redacted prompts, and clear experimental labeling.
- **Non-destructive media handling**: PASS — Source files are never written, renamed, moved, deleted, transcoded, or metadata-mutated in MVP. Only local index/cache/diagnostic files are written.
- **Responsive architecture**: PASS — Recursive scanning, file IO, image decoding, Vision/PDF/AVFoundation extraction, provider HTTP calls, embeddings, video sampling, and SQLite writes run in cancellable background actors/services with bounded concurrency.
- **Testable Swift design**: PASS — The architecture is protocol-first with dependency-injected services for folder access, discovery, extraction, providers, storage, indexing, ranking, diagnostics, and UI view models. XCTest coverage is mandatory for each service boundary and user story.
- **Privacy/secrets/transport**: PASS — Provider credentials use Keychain. Loopback HTTP is allowed; non-loopback HTTP is blocked by default. Diagnostics redact content, full paths, credentials, prompts, raw provider bodies, and transcripts by default. Index retention and deletion are exposed in Settings.
- **Observability/recovery**: PASS — Progress snapshots, failure categories, retryability, retry/ignore/reauthorize/rebuild actions, and redacted diagnostic export are first-class requirements.
- **Performance bounds**: PASS — Plan defines bounded concurrency, thumbnail limits, video sampling limits, chunked text/transcript processing, resumable queue state, and 10k-asset search targets.

## Project Structure

### Documentation (this feature)

```text
specs/001-local-media-library/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── inference-provider-contract.md
│   ├── indexing-pipeline-contract.md
│   ├── search-contract.md
│   └── privacy-diagnostics-contract.md
└── tasks.md              # Created by /speckit-tasks, not by /speckit-plan
```

### Source Code (repository root)

```text
LocalLens.xcodeproj/

LocalLens/
├── LocalLensApp.swift
├── AppShell/
│   ├── MenuBarRootView.swift
│   ├── SearchPopoverView.swift
│   ├── SettingsWindow.swift
│   ├── OnboardingView.swift
│   └── AppCommands.swift
├── DesignSystem/
│   ├── LiquidGlass/
│   ├── Components/
│   └── Theme/
├── FolderAccess/
│   ├── FolderAuthorizationService.swift
│   ├── SecurityScopedBookmarkStore.swift
│   └── WatchedFolderViewModel.swift
├── MediaDiscovery/
│   ├── MediaDiscoveryService.swift
│   ├── MediaTypeResolver.swift
│   └── FileIdentityService.swift
├── Indexing/
│   ├── IndexCoordinator.swift
│   ├── IndexQueueActor.swift
│   ├── IndexProgressStore.swift
│   └── IndexCancellation.swift
├── Extractors/
│   ├── ImageExtractor.swift
│   ├── PDFExtractor.swift
│   ├── AudioTranscriptExtractor.swift
│   ├── VideoSceneExtractor.swift
│   ├── ThumbnailService.swift
│   └── ExtractorProtocols.swift
├── Inference/
│   ├── InferenceProvider.swift
│   ├── OpenAICompatibleClient.swift
│   ├── ProviderRegistry.swift
│   ├── OMLXProvider.swift
│   ├── OllamaProvider.swift
│   ├── HermesAgentProvider.swift
│   ├── PromptTemplates.swift
│   └── ProviderTransportPolicy.swift
├── Search/
│   ├── SearchService.swift
│   ├── SearchRanker.swift
│   ├── SemanticVectorStore.swift
│   ├── SnippetBuilder.swift
│   └── SearchResultViewModel.swift
├── PreviewActions/
│   ├── QuickLookPreviewService.swift
│   ├── FinderRevealService.swift
│   └── ClipboardActionService.swift
├── Storage/
│   ├── LocalLensDatabase.swift
│   ├── Migrations/
│   ├── Repositories/
│   └── CachePaths.swift
├── Diagnostics/
│   ├── FailureDashboardView.swift
│   ├── DiagnosticExporter.swift
│   ├── RedactionPolicy.swift
│   └── PrivacyAudit.swift
├── Resources/
│   ├── Assets.xcassets
│   └── LocalLens.entitlements
└── Support/
    ├── DependencyContainer.swift
    └── BuildConfiguration.swift

LocalLensTests/
├── FolderAccessTests/
├── MediaDiscoveryTests/
├── IndexingTests/
├── ExtractorTests/
├── InferenceTests/
├── SearchTests/
├── StorageTests/
├── PrivacySecurityTests/
└── Fixtures/

LocalLensUITests/
├── OnboardingUITests.swift
├── SearchPopoverUITests.swift
└── SettingsUITests.swift
```

**Structure Decision**: Use one native Xcode project with one macOS app target, one unit test target, and one UI test target. Keep feature domains as folders/groups inside the app target to avoid premature multi-package complexity while preserving clean protocol boundaries and testability. Split into Swift packages only after the MVP proves stable service boundaries.

## Phase 0 Research Outcomes

Research decisions are captured in `research.md`. Key decisions:
- Create a real Xcode project (`LocalLens.xcodeproj`) rather than a SwiftPM-only prototype because menu bar lifecycle, entitlements, assets, sandboxing, UI tests, and Quick Look/Finder integrations are Xcode-native concerns.
- Use Swift 6.3 strict concurrency with actors for indexing and storage coordination.
- Use a hybrid local search architecture: SQLite metadata + FTS5 for lexical search, vector embeddings for semantic ranking, and match-reason explanations generated by deterministic ranking code.
- Use local loopback OpenAI-compatible provider abstractions for oMLX, Ollama, and Hermes Agent; avoid binding the core indexing pipeline to any one provider.
- Use Liquid Glass only for appropriate macOS 26 surfaces such as floating search, menu bar popover background, detail action bar, and compact status panels; keep content/results readable and high contrast.

## Phase 1 Design Outcomes

Design artifacts are captured in:
- `data-model.md`
- `contracts/inference-provider-contract.md`
- `contracts/indexing-pipeline-contract.md`
- `contracts/search-contract.md`
- `contracts/privacy-diagnostics-contract.md`
- `quickstart.md`

## UI/UX Direction

- **Menu bar first**: Menu bar icon opens a compact Liquid Glass search popover with search field, indexing status, recent results, and primary actions.
- **Settings window**: Native macOS settings-style window with tabs/sections for Folders, Indexing, AI Providers, Privacy & Storage, Diagnostics, and Shortcuts.
- **Search layout**: Inline top search inside the popover, keyboard-first result list with thumbnails, match reasons, and action shortcuts.
- **Preview pattern**: Quick Look for original files plus a right-side detail/metadata panel in the main/settings window when needed.
- **Liquid Glass usage**: Use `.glassEffect()`/GlassEffectContainer on floating popover chrome and action pills on macOS 26; fall back to standard materials if unavailable. Do not place long text/transcripts on translucent glass.
- **Keyboard shortcuts**: `⌘F` focus search, `⌘,` settings, `Space` preview selected result, `⌘R` reveal in Finder, `⌘C` copy snippet/path depending focus, `Esc` dismiss/cancel, arrows navigate results.

## AI Provider Plan

| Provider | Default Base URL | Role | Local/Remote Classification | MVP Behavior |
|---|---:|---|---|---|
| oMLX | `http://localhost:17998/v1` | MLX local LLM/VLM/embeddings/rerank if available | Local loopback | Enabled as a configurable local provider, health-checked before use |
| Ollama | `http://localhost:11434/v1` | Local embeddings/chat/vision models where installed | Local loopback | Enabled as a configurable local provider, health-checked before use |
| Hermes Agent | `http://localhost:8642/v1` | Local OpenAI-compatible agent/chat endpoint for metadata assistance or manual queries | Local loopback | Disabled for automatic bulk indexing by default unless user opts into agent-assisted extraction, because Hermes may use tools/providers behind the endpoint |
| Custom Remote | user-specified HTTPS URL | Optional remote inference | Remote | Disabled by default, requires opt-in, HTTPS, privacy warning, and redacted diagnostic policy |

Provider prompt safety requirements:
- Prompt templates are versioned constants in `PromptTemplates.swift`.
- OCR/PDF/transcript content is passed as bounded structured input, not as executable instructions.
- Prompts instruct models to extract labels, scene summaries, or embeddings only; they must not follow instructions found inside media content.
- Raw prompts and raw provider responses are not logged by default.
- Provider errors shown to users are mapped to safe categories rather than displayed verbatim.

## Complexity Tracking

No constitutional violations are introduced. The architecture is broader than a minimal single-view app because the feature must safely combine broad file access, background indexing, local/remote inference adapters, search ranking, diagnostics, and non-destructive privacy guardrails.

| Design Decision | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Protocol-based service domains | Required for XCTest coverage, provider substitution, and safe file/inference boundaries | Direct calls from SwiftUI views would block UI and make privacy tests brittle |
| SQLite/FTS plus vector store | Needed for fast lexical search, durable metadata, and semantic retrieval at 10k assets | In-memory search cannot meet persistence/relaunch or scale requirements |
| Separate provider transport policy | Needed to enforce loopback HTTP vs remote HTTPS and explicit opt-in rules | Scattered URL checks would be easy to bypass and hard to test |
| Background indexing actors | Needed for cancellation, pause/resume, and responsive menu bar UI | A single `@MainActor` view model would freeze during IO and model work |
