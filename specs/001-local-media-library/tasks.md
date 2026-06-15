# Tasks: LocalLens Private Media Library MVP

**Input**: Design documents from `/specs/001-local-media-library/`

**Prerequisites**: `specs/001-local-media-library/plan.md`, `specs/001-local-media-library/spec.md`, `specs/001-local-media-library/research.md`, `specs/001-local-media-library/data-model.md`, `specs/001-local-media-library/contracts/`, `specs/001-local-media-library/quickstart.md`

**Tests**: Mandatory. The LocalLens constitution and plan require XCTest, integration fixtures, privacy/file-access/inference/cancellation tests, and build verification.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently after shared foundations are complete.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel because it touches different files or does not depend on incomplete tasks.
- **[Story]**: User story label from `specs/001-local-media-library/spec.md`.
- Every task names an exact file path or repository config file.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the native Xcode project, target scaffolding, entitlements, fixtures, and base folders required before feature work.

- [X] T001 Create native macOS SwiftUI Xcode project with app, unit test, and UI test targets in `LocalLens.xcodeproj/project.pbxproj`
- [X] T002 Configure macOS 26.0 deployment target, Swift 6 language mode, strict concurrency, app sandbox, read-only user-selected file access, security-scoped bookmarks, and network client entitlements in `LocalLens.xcodeproj/project.pbxproj`
- [X] T003 Create LocalLens app entry point and menu bar scene in `LocalLens/LocalLensApp.swift`
- [X] T004 Create app entitlements file with sandbox, read-only user-selected file access, security-scoped bookmarks, and network client keys in `LocalLens/Resources/LocalLens.entitlements`
- [X] T005 [P] Create source folder structure from the implementation plan in `LocalLens/Support/DependencyContainer.swift`
- [X] T006 [P] Create unit test folder structure and base test utilities in `LocalLensTests/Support/TestDependencyFactory.swift`
- [X] T007 [P] Create UI test folder structure and launch helpers in `LocalLensUITests/Support/LocalLensUITestBase.swift`
- [X] T008 [P] Create fixture manifest for screenshots, PDFs, audio, video, corrupted files, and permission cases in `LocalLensTests/Fixtures/fixture-manifest.json`
- [X] T009 Configure GRDB.swift or thin SQLite package dependency and linker settings in `LocalLens.xcodeproj/project.pbxproj`
- [X] T010 Add build configuration constants for macOS version, provider URLs, queue limits, thumbnail bounds, and video sampling bounds in `LocalLens/Support/BuildConfiguration.swift`
- [X] T011 Verify the generated project builds with XCodeMCP or xcodebuild and record the command in `specs/001-local-media-library/quickstart.md`

**Checkpoint**: Xcode project exists and the empty app/test targets build.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement shared models, persistence, provider guardrails, indexing primitives, diagnostics, and dependency injection that all stories depend on.

**Critical**: No user story implementation should begin until these foundations are complete.

- [X] T012 Define core Sendable domain enums for media type, index state, job type, extraction stage, match reason, authorization state, provider locality, transport state, and failure category in `LocalLens/Storage/Models/DomainEnums.swift`
- [X] T013 [P] Define WatchedFolder, MediaAsset, ExtractionRecord, SearchableChunk, IndexJob, IndexFailure, ProviderSetting, SearchRequest, and SearchResultDTO domain models in `LocalLens/Storage/Models/LocalLensModels.swift`
- [X] T014 Create SQLite schema version 1 with tables, indexes, FTS5 schema, vector metadata table, and migration runner in `LocalLens/Storage/Migrations/MigrationV1.swift`
- [X] T015 Implement LocalLensDatabase actor with serialized transactions, Application Support paths, schema migration, cache path creation, and corruption error mapping in `LocalLens/Storage/LocalLensDatabase.swift`
- [X] T016 [P] Implement repository protocols for watched folders, assets, chunks, jobs, failures, providers, and settings in `LocalLens/Storage/Repositories/RepositoryProtocols.swift`
- [X] T017 Implement SQLite-backed repositories for watched folders, assets, chunks, jobs, failures, providers, and settings in `LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [X] T018 [P] Implement app-private cache path resolution for thumbnails, transcripts, keyframes, diagnostics, and temporary files in `LocalLens/Storage/CachePaths.swift`
- [X] T019 [P] Implement redaction policy for paths, prompts, transcripts, extracted text, credentials, raw provider bodies, and diagnostics in `LocalLens/Diagnostics/RedactionPolicy.swift`
- [X] T020 [P] Implement Keychain-backed provider secret storage in `LocalLens/Inference/ProviderCredentialStore.swift`
- [X] T021 [P] Implement provider URL normalization and loopback/HTTPS transport decisions in `LocalLens/Inference/ProviderTransportPolicy.swift`
- [X] T022 Implement OpenAI-compatible HTTP client for `/models`, `/embeddings`, and `/chat/completions` with timeout, cancellation, bounded body logging, and redacted error mapping in `LocalLens/Inference/OpenAICompatibleClient.swift`
- [X] T023 Implement provider registry defaults for oMLX, Ollama, Hermes Agent, and disabled custom remote provider in `LocalLens/Inference/ProviderRegistry.swift`
- [X] T024 [P] Implement prompt templates that treat media-derived text as untrusted data and enforce size bounds in `LocalLens/Inference/PromptTemplates.swift`
- [X] T025 [P] Implement index cancellation token, pause state, progress sink, and progress snapshot types in `LocalLens/Indexing/IndexCancellation.swift`
- [X] T026 Implement IndexQueueActor with durable queue loading, priority ordering, pause, resume, cancel, retry, and relaunch recovery primitives in `LocalLens/Indexing/IndexQueueActor.swift`
- [X] T027 Implement dependency container wiring repositories, provider registry, extractors, indexing, search, preview actions, diagnostics, and view models in `LocalLens/Support/DependencyContainer.swift`
- [X] T028 [P] Create XCTest coverage for SQLite migrations and repository CRUD in `LocalLensTests/StorageTests/LocalLensDatabaseTests.swift`
- [X] T029 [P] Create XCTest coverage for provider URL normalization, loopback HTTP allowance, non-loopback HTTP blocking, HTTPS remote opt-in, and Keychain secret persistence in `LocalLensTests/InferenceTests/ProviderTransportPolicyTests.swift`
- [X] T030 [P] Create XCTest coverage for prompt injection resistance, prompt size bounds, and redacted provider errors in `LocalLensTests/InferenceTests/PromptTemplatesTests.swift`
- [X] T031 [P] Create XCTest coverage for queue pause, resume, cancel, retry, and relaunch state transitions in `LocalLensTests/IndexingTests/IndexQueueActorTests.swift`

**Checkpoint**: Shared storage, inference guardrails, queue primitives, and test harness are ready.

---

## Phase 3: User Story 1 - Add Private Media Library Folders (Priority: P1)

**Goal**: A user can authorize folders, persist access across relaunch, manage watched folders in Settings, and queue discovery for supported media.

**Independent Test**: Starting from a fresh install, add a folder, see it listed in Settings, relaunch, confirm authorization or reauthorization state, remove it, and verify source files are unchanged.

### Tests for User Story 1 (Mandatory)

- [X] T032 [P] [US1] Create XCTest for security-scoped bookmark save, restore, stale bookmark, denied access, and balanced start/stop behavior in `LocalLensTests/FolderAccessTests/SecurityScopedBookmarkStoreTests.swift`
- [X] T033 [P] [US1] Create XCTest for watched folder add, enable, disable, remove, relaunch restoration, and index cleanup without source deletion in `LocalLensTests/FolderAccessTests/WatchedFolderRepositoryTests.swift`
- [X] T034 [P] [US1] Create XCTest for recursive discovery of supported media types and ignored unsupported files in `LocalLensTests/MediaDiscoveryTests/MediaDiscoveryServiceTests.swift`
- [X] T035 [P] [US1] Create UI test for first folder onboarding, add-folder panel flow, Settings folder list, and removal confirmation in `LocalLensUITests/OnboardingUITests.swift`

### Implementation for User Story 1

- [X] T036 [P] [US1] Implement security-scoped bookmark persistence and access tokens in `LocalLens/FolderAccess/SecurityScopedBookmarkStore.swift`
- [X] T037 [US1] Implement NSOpenPanel folder authorization, reauthorization, stale access handling, and removal semantics in `LocalLens/FolderAccess/FolderAuthorizationService.swift`
- [X] T038 [P] [US1] Implement UTType resolution for PNG, JPEG, HEIC, TIFF, WebP, PDF, MP3, M4A, WAV, AAC, MP4, MOV, and M4V in `LocalLens/MediaDiscovery/MediaTypeResolver.swift`
- [X] T039 [P] [US1] Implement file identity and file signature capture for supported media in `LocalLens/MediaDiscovery/FileIdentityService.swift`
- [X] T040 [US1] Implement recursive media discovery with hidden/package/symlink/permission handling and discovery job creation in `LocalLens/MediaDiscovery/MediaDiscoveryService.swift`
- [X] T041 [US1] Implement watched folder state view model with add, enable, disable, remove, reauthorize, and queue-discovery actions in `LocalLens/FolderAccess/WatchedFolderViewModel.swift`
- [X] T042 [US1] Implement first-run onboarding view with privacy promise, folder access explanation, and add-folder call to action in `LocalLens/AppShell/OnboardingView.swift`
- [X] T043 [US1] Implement Settings folder management section with authorization state, last scan time, enable toggle, remove action, and reauthorize action in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T044 [US1] Wire menu bar app lifecycle to show onboarding when no watched folders exist and queue discovery after folder addition in `LocalLens/AppShell/MenuBarRootView.swift`

**Checkpoint**: User Story 1 is independently usable and tested.

---

## Phase 4: User Story 2 - Index Screenshots, Images, and PDFs (Priority: P1)

**Goal**: Images, screenshots, and PDFs are indexed locally with thumbnails, OCR/PDF text, visual labels when available, searchable chunks, and partial/failure state.

**Independent Test**: With fixture images/screenshots/PDFs, indexing completes and search can retrieve visible image text, selectable PDF text, and visual concepts with thumbnails.

### Tests for User Story 2 (Mandatory)

- [X] T045 [P] [US2] Create XCTest for bounded thumbnail generation across images and PDFs in `LocalLensTests/ExtractorTests/ThumbnailServiceTests.swift`
- [X] T046 [P] [US2] Create XCTest for image OCR, dimensions, visual labels, and corrupt image failure categories in `LocalLensTests/ExtractorTests/ImageExtractorTests.swift`
- [X] T047 [P] [US2] Create XCTest for PDF selectable text, image-page OCR fallback, page count, password-protected PDFs, and partial page failures in `LocalLensTests/ExtractorTests/PDFExtractorTests.swift`
- [X] T048 [P] [US2] Create XCTest for chunk creation, FTS insertion, embedding fallback, and complete/partial asset commits for image/PDF records in `LocalLensTests/IndexingTests/ImagePDFIndexingPipelineTests.swift`

### Implementation for User Story 2

- [X] T049 [P] [US2] Define extractor protocols, extraction result types, and safe error mapping in `LocalLens/Extractors/ExtractorProtocols.swift`
- [X] T050 [P] [US2] Implement bounded image/PDF thumbnail generation with cache writes under Application Support in `LocalLens/Extractors/ThumbnailService.swift`
- [X] T051 [US2] Implement image metadata extraction, Vision OCR, visual label extraction, and corrupt file handling in `LocalLens/Extractors/ImageExtractor.swift`
- [X] T052 [US2] Implement PDFKit page count, selectable text extraction, bounded image-page OCR, and password/partial failure handling in `LocalLens/Extractors/PDFExtractor.swift`
- [X] T053 [US2] Implement searchable chunk builder for filenames, OCR text, PDF text, visual labels, page context, and bounded text chunks in `LocalLens/Indexing/SearchableChunkBuilder.swift`
- [X] T054 [US2] Implement embedding job stage with local provider fallback and no-provider graceful degradation in `LocalLens/Indexing/EmbeddingStageService.swift`
- [X] T055 [US2] Integrate image/PDF stages into IndexCoordinator with durable complete, partial, failed, and cancelled commits in `LocalLens/Indexing/IndexCoordinator.swift`
- [X] T056 [US2] Add Settings indexing state for image/PDF stage counts and last indexed time in `LocalLens/AppShell/SettingsWindow.swift`

**Checkpoint**: User Story 2 delivers the image/PDF alpha cutline.

---

## Phase 5: User Story 3 - Search by Meaning, Text, Objects, Transcript, or Scene (Priority: P1)

**Goal**: A user can run natural-language searches across filenames, OCR, PDF text, transcripts, labels, semantic metadata, and see ranked results with match explanations.

**Independent Test**: After fixture indexing, search for exact text, semantic concepts, and transcript-like phrases; verify ranking, snippets, empty states, and missing file handling.

### Tests for User Story 3 (Mandatory)

- [ ] T057 [P] [US3] Create XCTest for SearchRequest validation, empty queries, query length bounds, and sensitive query diagnostic exclusion in `LocalLensTests/SearchTests/SearchRequestTests.swift`
- [ ] T058 [P] [US3] Create XCTest for FTS search across filenames, OCR text, PDF text, transcript text, and visual labels in `LocalLensTests/SearchTests/FTSSearchTests.swift`
- [ ] T059 [P] [US3] Create XCTest for semantic vector candidate scoring, no-provider fallback, and dimension mismatch handling in `LocalLensTests/SearchTests/SemanticVectorStoreTests.swift`
- [ ] T060 [P] [US3] Create XCTest for deterministic ranking, match reasons, snippets, page hints, timestamp hints, and missing-file exclusion in `LocalLensTests/SearchTests/SearchRankerTests.swift`
- [ ] T061 [P] [US3] Create UI test for menu bar search, keyboard navigation, empty state, and visible match reasons in `LocalLensUITests/SearchPopoverUITests.swift`

### Implementation for User Story 3

- [ ] T062 [P] [US3] Implement semantic vector storage, cosine scoring, model-dimension checks, and local-only query embedding calls in `LocalLens/Search/SemanticVectorStore.swift`
- [ ] T063 [P] [US3] Implement snippet generation with bounded context and no unrelated extracted content exposure in `LocalLens/Search/SnippetBuilder.swift`
- [ ] T064 [US3] Implement SearchRanker with lexical score, semantic score, exact phrase boosts, media relevance, page/timestamp context, and missing/stale penalties in `LocalLens/Search/SearchRanker.swift`
- [ ] T065 [US3] Implement SearchService with debounced cancellable query execution, lexical-first results, semantic refinement, and result DTO mapping in `LocalLens/Search/SearchService.swift`
- [ ] T066 [US3] Implement SearchResultViewModel for query state, results, selection, empty states, match reasons, and keyboard commands in `LocalLens/Search/SearchResultViewModel.swift`
- [ ] T067 [US3] Implement Liquid Glass search popover with search field, result rows, thumbnails, match reasons, snippets, page/timestamp hints, and empty state in `LocalLens/AppShell/SearchPopoverView.swift`
- [ ] T068 [US3] Wire menu bar search presentation, shortcut focus, Escape dismissal, and indexing status summary in `LocalLens/AppShell/MenuBarRootView.swift`

**Checkpoint**: User Story 3 completes the core searchable private media library MVP for folders plus image/PDF indexing plus search.

---

## Phase 6: User Story 4 - Index Audio and Video Privately (Priority: P2)

**Goal**: Audio and video files are indexed privately with duration metadata, transcripts when local transcription succeeds, representative thumbnails/keyframes, sampled scene metadata, and safe failure handling.

**Independent Test**: With short fixture audio/video files, search retrieves spoken transcript text and sampled scene/frame text while corrupted or unsupported files record safe failures.

### Tests for User Story 4 (Mandatory)

- [ ] T069 [P] [US4] Create XCTest for audio duration metadata, local transcript chunks, provider unavailable fallback, and corrupt audio failure categories in `LocalLensTests/ExtractorTests/AudioTranscriptExtractorTests.swift`
- [ ] T070 [P] [US4] Create XCTest for video duration metadata, representative keyframes, sampled frame OCR/labels, audio track transcript, and large-video sampling bounds in `LocalLensTests/ExtractorTests/VideoSceneExtractorTests.swift`
- [ ] T071 [P] [US4] Create XCTest for audio/video index pipeline partial states, timestamped chunks, provider timeouts, and no source mutation in `LocalLensTests/IndexingTests/AudioVideoIndexingPipelineTests.swift`

### Implementation for User Story 4

- [ ] T072 [P] [US4] Implement audio duration metadata extraction, bounded transcript provider calls, timestamped transcript chunk mapping, and failure categories in `LocalLens/Extractors/AudioTranscriptExtractor.swift`
- [ ] T073 [P] [US4] Implement video duration metadata, keyframe thumbnail extraction, bounded frame sampling, frame OCR/labels, audio-track transcription coordination, and failure categories in `LocalLens/Extractors/VideoSceneExtractor.swift`
- [ ] T074 [US4] Integrate audio/video extractor stages, timestamped chunk storage, sampled scene metadata, and complete/partial commits into IndexCoordinator in `LocalLens/Indexing/IndexCoordinator.swift`
- [ ] T075 [US4] Add audio/video indexing progress, skipped-provider messaging, and stage counts to Settings indexing UI in `LocalLens/AppShell/SettingsWindow.swift`
- [ ] T076 [US4] Extend search result rendering for audio/video duration and timestamp jump hints in `LocalLens/AppShell/SearchPopoverView.swift`

**Checkpoint**: User Story 4 adds the full mixed-media promise behind existing indexing/search foundations.

---

## Phase 7: User Story 5 - Preview, Reveal, and Reuse Results (Priority: P2)

**Goal**: Search results can be previewed, revealed in Finder, opened with the default app, and copied as path or safe snippet using mouse or keyboard.

**Independent Test**: From a result list, keyboard-select a result, preview it, reveal it, open it, copy path, and copy a bounded snippet without modifying source files.

### Tests for User Story 5 (Mandatory)

- [ ] T077 [P] [US5] Create XCTest for Quick Look preview URL validation and missing-file behavior in `LocalLensTests/PreviewActionTests/QuickLookPreviewServiceTests.swift`
- [ ] T078 [P] [US5] Create XCTest for Finder reveal, default open, copy path, copy snippet, and source byte preservation in `LocalLensTests/PreviewActionTests/ResultActionServiceTests.swift`
- [ ] T079 [P] [US5] Create UI test for keyboard-driven result selection, Space preview, reveal shortcut, copy actions, and Settings shortcut visibility in `LocalLensUITests/SearchPopoverUITests.swift`

### Implementation for User Story 5

- [ ] T080 [P] [US5] Implement Quick Look preview service with security-scoped access, missing-file checks, and no source writes in `LocalLens/PreviewActions/QuickLookPreviewService.swift`
- [ ] T081 [P] [US5] Implement Finder reveal, system open, clipboard path copy, and bounded snippet copy services in `LocalLens/PreviewActions/FinderRevealService.swift`
- [ ] T082 [P] [US5] Implement shared clipboard result action service with redacted snippet bounds in `LocalLens/PreviewActions/ClipboardActionService.swift`
- [ ] T083 [US5] Add result action commands, keyboard shortcuts, disabled states, and toast feedback to `LocalLens/AppShell/AppCommands.swift`
- [ ] T084 [US5] Add floating Liquid Glass result action bar and per-result action menu to `LocalLens/AppShell/SearchPopoverView.swift`

**Checkpoint**: User Story 5 makes search results immediately actionable.

---

## Phase 8: User Story 6 - Monitor and Control Indexing (Priority: P2)

**Goal**: Users can see indexing progress and control long-running work with pause, resume, cancel, retry failures, reindex file, and reindex folder actions.

**Independent Test**: During a mixed-library indexing run, progress counts update; pause/resume/cancel work; retry and reindex actions update durable queue state without partial-complete records.

### Tests for User Story 6 (Mandatory)

- [ ] T085 [P] [US6] Create XCTest for IndexProgressStore snapshots, queue counts, last indexed time, and redacted current labels in `LocalLensTests/IndexingTests/IndexProgressStoreTests.swift`
- [ ] T086 [P] [US6] Create XCTest for retry failed job, reindex asset, reindex folder, ignore failure, and no partial-complete records after cancel in `LocalLensTests/IndexingTests/IndexControlActionsTests.swift`
- [ ] T087 [P] [US6] Create UI test for progress display, pause, resume, cancel, retry, and reindex controls in `LocalLensUITests/SettingsUITests.swift`

### Implementation for User Story 6

- [ ] T088 [P] [US6] Implement progress snapshot persistence and AsyncStream progress publishing in `LocalLens/Indexing/IndexProgressStore.swift`
- [ ] T089 [US6] Extend IndexCoordinator with pause, resume, cancel, retry failure, reindex asset, reindex folder, and cleanup-missing orchestration in `LocalLens/Indexing/IndexCoordinator.swift`
- [ ] T090 [US6] Implement failure dashboard model for safe categories, retryability, and recovery actions in `LocalLens/Diagnostics/FailureDashboardView.swift`
- [ ] T091 [US6] Add indexing status pill, progress counts, pause/resume/cancel actions, and failure count summary to `LocalLens/AppShell/MenuBarRootView.swift`
- [ ] T092 [US6] Add Settings indexing controls for queue state, retry, ignore, reindex file, reindex folder, and rebuild queue actions in `LocalLens/AppShell/SettingsWindow.swift`

**Checkpoint**: User Story 6 makes long-running indexing observable and controllable.

---

## Phase 9: User Story 7 - Understand Privacy, Storage, and Failures (Priority: P3)

**Goal**: Users understand local-first processing, manage local storage, delete/rebuild the index, review provider privacy state, and export redacted diagnostics.

**Independent Test**: Complete onboarding, view privacy/storage, confirm remote AI is disabled by default, export diagnostics, verify redaction, and rebuild/delete the index without changing source files.

### Tests for User Story 7 (Mandatory)

- [ ] T093 [P] [US7] Create XCTest for diagnostic export redaction of paths, prompts, transcripts, extracted text, credentials, thumbnails, and raw provider bodies in `LocalLensTests/PrivacySecurityTests/DiagnosticExporterTests.swift`
- [ ] T094 [P] [US7] Create XCTest for storage usage calculation, index deletion, index rebuild queueing, and source byte preservation in `LocalLensTests/PrivacySecurityTests/StorageManagementTests.swift`
- [ ] T095 [P] [US7] Create XCTest for default provider settings, Hermes Agent automatic-indexing disabled state, remote provider opt-in warning, and non-loopback transmission guardrails in `LocalLensTests/PrivacySecurityTests/ProviderPrivacyDefaultsTests.swift`
- [ ] T096 [P] [US7] Create UI test for onboarding privacy copy, AI provider settings, privacy/storage controls, diagnostic export, and failure dashboard recovery actions in `LocalLensUITests/SettingsUITests.swift`

### Implementation for User Story 7

- [ ] T097 [P] [US7] Implement diagnostic exporter with safe counts, provider health summaries, hashed paths, omitted transcripts, omitted extracted text, omitted credentials, and omitted raw provider bodies in `LocalLens/Diagnostics/DiagnosticExporter.swift`
- [ ] T098 [P] [US7] Implement privacy audit service for remote transmission checks, source mutation checks, provider default checks, and diagnostic redaction checks in `LocalLens/Diagnostics/PrivacyAudit.swift`
- [ ] T099 [US7] Implement storage usage, delete index, rebuild index, and cache cleanup actions in `LocalLens/Storage/Repositories/StorageMaintenanceRepository.swift`
- [ ] T100 [US7] Add Privacy & Storage Settings section with local index path, size, delete, rebuild, and privacy explanation in `LocalLens/AppShell/SettingsWindow.swift`
- [ ] T101 [US7] Add AI Providers Settings section with oMLX, Ollama, Hermes Agent, custom remote, health checks, transport warnings, Keychain credential state, and explicit remote opt-in in `LocalLens/AppShell/SettingsWindow.swift`
- [ ] T102 [US7] Add Diagnostics Settings section with failure dashboard, retry/ignore/reauthorize/rebuild actions, and redacted export button in `LocalLens/AppShell/SettingsWindow.swift`

**Checkpoint**: User Story 7 completes trust, storage, provider, and diagnostic controls.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, performance, accessibility, Liquid Glass polish, docs, and final verification across all user stories.

- [ ] T103 [P] Add accessibility identifiers, VoiceOver labels, reduced transparency fallbacks, reduced motion handling, and keyboard focus rings across app views in `LocalLens/DesignSystem/Components/AccessibilitySupport.swift`
- [ ] T104 [P] Implement macOS 26 Liquid Glass design tokens, fallback materials, contrast-safe surfaces, and reusable glass action components in `LocalLens/DesignSystem/LiquidGlass/LiquidGlassComponents.swift`
- [ ] T105 [P] Add native macOS visual theme tokens for light mode, dark mode, system accent color, typography, spacing, thumbnails, and status colors in `LocalLens/DesignSystem/Theme/LocalLensTheme.swift`
- [ ] T106 [P] Create 10,000-asset synthetic search performance fixture and benchmark harness in `LocalLensTests/SearchTests/SearchPerformanceTests.swift`
- [ ] T107 [P] Create 1,000-file mixed-media indexing responsiveness test harness with pause/resume/cancel assertions in `LocalLensTests/IndexingTests/IndexingResponsivenessTests.swift`
- [ ] T108 [P] Create non-destructive source byte comparison helper and apply it to fixture media flows in `LocalLensTests/PrivacySecurityTests/SourceMutationGuardTests.swift`
- [ ] T109 [P] Add app icon, menu bar template image, accent colors, and placeholder thumbnails in `LocalLens/Resources/Assets.xcassets`
- [ ] T110 Update quickstart with final XCodeMCP build, test, provider-health, and manual smoke-test steps in `specs/001-local-media-library/quickstart.md`
- [ ] T111 Run full unit test target and record passing command/output summary in `specs/001-local-media-library/quickstart.md`
- [ ] T112 Run UI smoke test target and record passing command/output summary in `specs/001-local-media-library/quickstart.md`
- [ ] T113 Build LocalLens app target with XCodeMCP or xcodebuild and record passing command/output summary in `specs/001-local-media-library/quickstart.md`
- [X] T114 Update `AGENTS.md` with implementation notes for XCodeMCP build usage, local provider defaults, redaction rules, and non-destructive source-file constraints

**Checkpoint**: MVP implementation is built, tested, documented, and ready for review.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; creates project skeleton and build target.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1**: Depends on Phase 2; enables folder authority and discovery.
- **Phase 4 US2**: Depends on Phase 2 and benefits from US1 discovery; provides image/PDF alpha indexing.
- **Phase 5 US3**: Depends on Phase 2 and is most useful after US1/US2; provides core search UX.
- **Phase 6 US4**: Depends on Phase 2 and integrates with US3 search; adds audio/video indexing.
- **Phase 7 US5**: Depends on US3 search results; adds preview/reveal/reuse actions.
- **Phase 8 US6**: Depends on Phase 2 and integrates with all indexing stories; adds controls and observability.
- **Phase 9 US7**: Depends on Phase 2 and integrates with provider, diagnostics, storage, and failure records.
- **Phase 10 Polish**: Depends on selected story scope completion.

### User Story Dependency Graph

```text
Foundation
├── US1 Add folders and discovery
│   └── US2 Image/PDF indexing
│       └── US3 Search UX
│           ├── US4 Audio/video indexing
│           └── US5 Preview/reveal/reuse
├── US6 Indexing control and progress
└── US7 Privacy/storage/failure trust controls
```

### MVP Cutlines

- **Minimal alpha**: Phase 1 + Phase 2 + US1 + US2 + US3.
- **Full mixed-media MVP**: Minimal alpha + US4 + US5 + US6 + US7.
- **Ship hardening**: Selected MVP scope + Phase 10 verification tasks.

---

## Parallel Opportunities

- Setup tasks T005, T006, T007, and T008 can run in parallel after T001-T004 project scaffolding decisions.
- Foundational model, redaction, Keychain, transport, prompt, and cancellation tasks T012-T025 can run in parallel where they touch separate files, then converge in T026-T027.
- Test tasks within each user story can be created in parallel before implementation.
- US2 extractors T050-T052 can be developed in parallel after T049.
- US3 search components T062-T063 can be developed in parallel before T064-T068 integration.
- US4 audio and video extractors T072-T073 can be developed in parallel before T074 integration.
- US5 preview, reveal, and clipboard services T080-T082 can be developed in parallel before T083-T084 integration.
- Polish tasks T103-T109 can run in parallel after the relevant UI/service surfaces exist.

## Parallel Example: User Story 1

```bash
Task: "T032 Create LocalLensTests/FolderAccessTests/SecurityScopedBookmarkStoreTests.swift"
Task: "T033 Create LocalLensTests/FolderAccessTests/WatchedFolderRepositoryTests.swift"
Task: "T034 Create LocalLensTests/MediaDiscoveryTests/MediaDiscoveryServiceTests.swift"
Task: "T035 Create LocalLensUITests/OnboardingUITests.swift"
```

## Parallel Example: User Story 2

```bash
Task: "T045 Create LocalLensTests/ExtractorTests/ThumbnailServiceTests.swift"
Task: "T046 Create LocalLensTests/ExtractorTests/ImageExtractorTests.swift"
Task: "T047 Create LocalLensTests/ExtractorTests/PDFExtractorTests.swift"
Task: "T049 Implement LocalLens/Extractors/ExtractorProtocols.swift"
Task: "T050 Implement LocalLens/Extractors/ThumbnailService.swift"
```

## Parallel Example: User Story 3

```bash
Task: "T057 Create LocalLensTests/SearchTests/SearchRequestTests.swift"
Task: "T058 Create LocalLensTests/SearchTests/FTSSearchTests.swift"
Task: "T059 Create LocalLensTests/SearchTests/SemanticVectorStoreTests.swift"
Task: "T062 Implement LocalLens/Search/SemanticVectorStore.swift"
Task: "T063 Implement LocalLens/Search/SnippetBuilder.swift"
```

## Parallel Example: User Story 4

```bash
Task: "T069 Create LocalLensTests/ExtractorTests/AudioTranscriptExtractorTests.swift"
Task: "T070 Create LocalLensTests/ExtractorTests/VideoSceneExtractorTests.swift"
Task: "T072 Implement LocalLens/Extractors/AudioTranscriptExtractor.swift"
Task: "T073 Implement LocalLens/Extractors/VideoSceneExtractor.swift"
```

## Parallel Example: User Story 5

```bash
Task: "T077 Create LocalLensTests/PreviewActionTests/QuickLookPreviewServiceTests.swift"
Task: "T078 Create LocalLensTests/PreviewActionTests/ResultActionServiceTests.swift"
Task: "T080 Implement LocalLens/PreviewActions/QuickLookPreviewService.swift"
Task: "T081 Implement LocalLens/PreviewActions/FinderRevealService.swift"
Task: "T082 Implement LocalLens/PreviewActions/ClipboardActionService.swift"
```

## Parallel Example: User Story 6

```bash
Task: "T085 Create LocalLensTests/IndexingTests/IndexProgressStoreTests.swift"
Task: "T086 Create LocalLensTests/IndexingTests/IndexControlActionsTests.swift"
Task: "T088 Implement LocalLens/Indexing/IndexProgressStore.swift"
```

## Parallel Example: User Story 7

```bash
Task: "T093 Create LocalLensTests/PrivacySecurityTests/DiagnosticExporterTests.swift"
Task: "T094 Create LocalLensTests/PrivacySecurityTests/StorageManagementTests.swift"
Task: "T095 Create LocalLensTests/PrivacySecurityTests/ProviderPrivacyDefaultsTests.swift"
Task: "T097 Implement LocalLens/Diagnostics/DiagnosticExporter.swift"
Task: "T098 Implement LocalLens/Diagnostics/PrivacyAudit.swift"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and confirm `LocalLens.xcodeproj/project.pbxproj` builds.
2. Complete Phase 2 foundations and keep all foundational XCTest passing.
3. Complete US1 to establish safe folder authority.
4. Complete US2 to deliver image/PDF indexing.
5. Complete US3 to deliver the searchable menu bar MVP.
6. Stop and validate the minimal alpha before adding audio/video, preview actions, indexing control polish, and privacy dashboards.

### Incremental Delivery

1. US1 demo: add/remove watched folder and persist authorization.
2. US2 demo: index screenshots/images/PDFs and retrieve OCR/PDF text.
3. US3 demo: search by text and meaning with ranked results and match reasons.
4. US4 demo: search audio/video transcripts and sampled scenes.
5. US5 demo: preview/reveal/open/copy results.
6. US6 demo: pause/resume/cancel/retry/reindex.
7. US7 demo: privacy/storage/diagnostic controls.

### Quality Gates

- Every story starts with failing tests for its independent acceptance criteria.
- Every completed story has passing unit tests and any relevant UI smoke tests.
- No source media mutation is allowed in any story.
- Remote/non-loopback inference remains disabled by default and transport-guarded.
- XCodeMCP or xcodebuild verifies the app target before implementation is marked complete.

## Task Summary

- **Total tasks**: 114
- **Setup**: 11 tasks
- **Foundational**: 20 tasks
- **US1 Add Private Media Library Folders**: 13 tasks
- **US2 Index Screenshots, Images, and PDFs**: 12 tasks
- **US3 Search by Meaning, Text, Objects, Transcript, or Scene**: 12 tasks
- **US4 Index Audio and Video Privately**: 8 tasks
- **US5 Preview, Reveal, and Reuse Results**: 8 tasks
- **US6 Monitor and Control Indexing**: 8 tasks
- **US7 Understand Privacy, Storage, and Failures**: 10 tasks
- **Polish & Cross-Cutting**: 12 tasks
- **Parallelizable tasks**: 64
