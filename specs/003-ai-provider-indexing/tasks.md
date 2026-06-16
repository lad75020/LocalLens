# Tasks: AI Provider Indexing Preferences

**Input**: Design documents from `/specs/003-ai-provider-indexing/`

**Prerequisites**: `specs/003-ai-provider-indexing/plan.md`, `specs/003-ai-provider-indexing/spec.md`, `specs/003-ai-provider-indexing/research.md`, `specs/003-ai-provider-indexing/data-model.md`, `specs/003-ai-provider-indexing/contracts/`, `specs/003-ai-provider-indexing/quickstart.md`

**Tests**: Tests are MANDATORY for LocalLens features. Write or update XCTest and UI tests before implementation for each user story; provider-routing tests must use injected clients or URLProtocol request capture that checks both `httpBody` and `httpBodyStream`.

**Organization**: Tasks are grouped by user story so each story can be independently implemented, tested, and demoed.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches a different file or independent test fixture.
- **[Story]**: User story traceability label for story-phase tasks only.
- Every task names an exact repository path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared test fixtures, request capture helpers, and implementation context before changing feature code.

- [x] T001 Review feature routing and safety scope in `specs/003-ai-provider-indexing/spec.md`, `specs/003-ai-provider-indexing/plan.md`, and `specs/003-ai-provider-indexing/contracts/provider-routing-contract.md`
- [x] T002 [P] Add AI-provider indexing fixture README and inventory in `LocalLens/LocalLensTests/Fixtures/AIProviderIndexing/README.md`
- [x] T003 [P] Add mock provider response fixtures for image, PDF, Office, embedding, and provider errors in `LocalLens/LocalLensTests/Fixtures/AIProviderIndexing/provider-responses.json`
- [x] T004 [P] Add provider request capture helper that reads `httpBody` and `httpBodyStream` in `LocalLens/LocalLensTests/Support/ProviderRequestCapture.swift`
- [x] T005 [P] Add deterministic prompt-injection text fixtures for image OCR, PDF text, and Office content in `LocalLens/LocalLensTests/Fixtures/AIProviderIndexing/prompt-injection-fixtures.json`
- [x] T006 [P] Add generated-content unique-token fixture constants for FTS assertions in `LocalLens/LocalLensTests/Support/GeneratedContentFixtureTokens.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core storage, prompt, readiness, and diagnostics infrastructure that all user stories depend on.

**Critical**: No user story implementation should begin until this phase is complete.

- [x] T007 [P] Extend extraction stages, match reasons, provider readiness, and generated-content kind enums in `LocalLens/LocalLens/Storage/Models/DomainEnums.swift`
- [x] T008 [P] Add generated content, preferred provider, embedding route, and routing failure model types in `LocalLens/LocalLens/Storage/Models/LocalLensModels.swift`
- [x] T009 Add additive SQLite migrations for preferred provider, generated content, fixed embedding metadata, and FTS compatibility in `LocalLens/LocalLens/Storage/LocalLensDatabase.swift`
- [x] T010 Update base schema definitions for fresh installs with generated content and fixed embedding route support in `LocalLens/LocalLens/Storage/Migrations/MigrationV1.swift`
- [x] T011 Extend repository protocols for preferred provider, generated content, readiness state, and route failure persistence in `LocalLens/LocalLens/Storage/Repositories/RepositoryProtocols.swift`
- [x] T012 Implement SQLite repositories for preferred provider, generated content, readiness state, and route failures in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T013 [P] Add migration and repository XCTest coverage for preferred provider and generated content persistence in `LocalLens/LocalLensTests/StorageTests/AIProviderIndexingStorageTests.swift`
- [x] T014 [P] Add provider readiness service contract and fixed embedding route validation in `LocalLens/LocalLens/Inference/ProviderReadinessService.swift`
- [x] T015 [P] Add provider routing service shell for image, PDF, Office, embedding, and audio/video skip decisions in `LocalLens/LocalLens/Inference/ProviderRoutingService.swift`
- [x] T016 [P] Add prompt template XCTest coverage for image description, PDF summary, Office summary, JSON shape, and untrusted-data boundaries in `LocalLens/LocalLensTests/InferenceTests/AIPromptTemplatesSafetyTests.swift`
- [x] T017 Update prompt templates for image long descriptions, PDF short summaries, and Office short summaries in `LocalLens/LocalLens/Inference/PromptTemplates.swift`
- [x] T018 [P] Add generated content chunk building support in `LocalLens/LocalLens/Indexing/GeneratedContentChunkBuilder.swift`
- [x] T019 [P] Add redaction tests for generated text, prompts, provider errors, full paths, and embeddings in `LocalLens/LocalLensTests/DiagnosticsTests/AIProviderIndexingRedactionTests.swift`
- [x] T020 Update diagnostics and privacy audit redaction coverage for provider routes, skipped stages, and generated text in `LocalLens/LocalLens/Diagnostics/DiagnosticExporter.swift` and `LocalLens/LocalLens/Diagnostics/PrivacyAudit.swift`
- [x] T021 Wire new repositories and services into the app dependency graph in `LocalLens/LocalLens/Support/DependencyContainer.swift`

**Checkpoint**: Storage, prompts, routing primitives, diagnostics redaction, and dependency injection are ready for story work.

---

## Phase 3: User Story 1 - Choose one preferred provider for descriptive indexing (Priority: P1) MVP

**Goal**: Users can select exactly one preferred AI provider for image long descriptions and PDF short summaries, and indexing sends image/PDF enrichment to only that provider.

**Independent Test**: Select a preferred provider, index one image and one PDF with request capture enabled, and confirm exactly one descriptive request is sent to the selected provider and no descriptive fallback occurs.

### Tests for User Story 1 (MANDATORY)

- [x] T022 [P] [US1] Add preferred provider persistence tests in `LocalLens/LocalLensTests/InferenceTests/PreferredAIProviderSelectionTests.swift`
- [x] T023 [P] [US1] Add image preferred-provider routing request tests in `LocalLens/LocalLensTests/PrivacySecurityTests/ImagePreferredProviderRoutingTests.swift`
- [x] T024 [P] [US1] Add PDF preferred-provider routing request tests in `LocalLens/LocalLensTests/PrivacySecurityTests/PDFPreferredProviderRoutingTests.swift`
- [x] T025 [P] [US1] Add missing, stale, transport-blocked, timeout, and no-fallback tests in `LocalLens/LocalLensTests/InferenceTests/PreferredProviderFailureTests.swift`
- [x] T026 [P] [US1] Add mixed image/PDF integration test with one captured provider per enrichment stage in `LocalLens/LocalLensTests/IndexingTests/PreferredProviderImagePDFIndexingTests.swift`

### Implementation for User Story 1

- [x] T027 [US1] Implement persisted preferred AI provider load/save operations in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T028 [US1] Normalize legacy provider rows as visible configuration targets before preferred-provider validation in `LocalLens/LocalLens/Inference/ProviderRegistry.swift`
- [x] T029 [US1] Implement single-provider inference and no-silent-fallback policy in `LocalLens/LocalLens/Inference/ProviderRoutingService.swift`
- [x] T030 [US1] Implement preferred provider readiness validation for Hermes, Ollama, oMLX, custom, credentials, and transport gates in `LocalLens/LocalLens/Inference/ProviderReadinessService.swift`
- [x] T031 [US1] Add image long-description provider call with bounded JSON parsing and safe failure mapping in `LocalLens/LocalLens/Extractors/ImageExtractor.swift`
- [x] T032 [US1] Add PDF short-summary provider call with bounded JSON parsing and safe failure mapping in `LocalLens/LocalLens/Extractors/PDFExtractor.swift`
- [x] T033 [US1] Capture preferred provider at asset-stage start in image/PDF paths in `LocalLens/LocalLens/Indexing/IndexCoordinator.swift`
- [x] T034 [US1] Record preferred-provider failures and retryability for image/PDF enrichment in `LocalLens/LocalLens/Indexing/IndexCoordinator.swift`
- [x] T035 [US1] Ensure provider request clients include selected model/profile metadata only for the selected provider in `LocalLens/LocalLens/Inference/OpenAICompatibleClient.swift`
- [x] T036 [US1] Add progress updates for image/PDF provider-backed stages within 2 seconds in `LocalLens/LocalLens/Indexing/IndexProgressStore.swift`
- [x] T037 [US1] Update source mutation guard coverage for image/PDF provider enrichment in `LocalLens/LocalLensTests/PrivacySecurityTests/SourceMutationGuardTests.swift`
- [x] T038 [US1] Verify User Story 1 with targeted XCTest and capture results in `specs/003-ai-provider-indexing/quickstart.md`

**Checkpoint**: User Story 1 independently delivers the MVP preferred-provider image/PDF route.

---

## Phase 4: User Story 2 - Enforce mandatory provider readiness without enable toggles (Priority: P1)

**Goal**: Settings removes provider enable toggles, shows all providers as configurable targets, and requires Hermes profile plus Ollama/oMLX generation model readiness before provider-backed work starts.

**Independent Test**: Open Settings, confirm provider enable toggles are absent, select required profiles/models, and verify readiness states block or allow provider-backed stages without hiding provider rows.

### Tests for User Story 2 (MANDATORY)

- [x] T039 [P] [US2] Add UI test asserting provider enable toggles are absent and preferred provider picker is present in `LocalLens/LocalLensUITests/SettingsAIProviderReadinessUITests.swift`
- [x] T040 [P] [US2] Add Hermes profile required-state UI test in `LocalLens/LocalLensUITests/SettingsHermesProfileSelectionUITests.swift`
- [x] T041 [P] [US2] Add Ollama and oMLX mandatory generation-model UI tests in `LocalLens/LocalLensUITests/SettingsProviderModelSelectionUITests.swift`
- [x] T042 [P] [US2] Add fixed Ollama embedding readiness display UI test in `LocalLens/LocalLensUITests/SettingsProviderModelSelectionUITests.swift`
- [x] T043 [P] [US2] Add remote privacy and transport warning UI test in `LocalLens/LocalLensUITests/SettingsAIProviderReadinessUITests.swift`
- [x] T044 [P] [US2] Add provider readiness unit tests for missing profile/model and stale selections in `LocalLens/LocalLensTests/InferenceTests/ProviderReadinessServiceTests.swift`

### Implementation for User Story 2

- [x] T045 [US2] Remove provider-level enable toggle controls from the AI Providers area in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T046 [US2] Add a single preferred AI provider picker with accessibility identifier `settingsPreferredAIProviderPicker` in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T047 [US2] Display readiness labels, safe errors, transport state, and credential state for every provider row in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T048 [US2] Display mandatory Hermes profile readiness for Hermes-backed image/PDF and Office stages in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T049 [US2] Display mandatory Ollama and oMLX generation model readiness separately from embedding readiness in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T050 [US2] Add fixed `qwen3-embedding:4b` readiness indicator with accessibility identifier `settingsFixedEmbeddingModelReadiness_ollama` in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T051 [US2] Persist Settings preferred provider changes through app settings repository bindings in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T052 [US2] Update Settings presenter refresh and error propagation for provider readiness in `LocalLens/LocalLens/AppShell/SettingsWindowPresenter.swift`
- [x] T053 [US2] Stop interpreting provider `is_enabled` as a user-facing setting in `LocalLens/LocalLens/Inference/ProviderSelectionService.swift`
- [x] T054 [US2] Add utility copy for readiness states and remote privacy warnings in `LocalLens/LocalLens/AppShell/SettingsWindow.swift`
- [x] T055 [US2] Verify User Story 2 with Settings UI tests and capture results in `specs/003-ai-provider-indexing/quickstart.md`

**Checkpoint**: Settings independently shows the required no-toggle readiness model.

---

## Phase 5: User Story 3 - Use fixed Ollama embeddings while making summaries searchable (Priority: P2)

**Goal**: Generated image descriptions, PDF summaries, and Office summaries are stored locally, searchable by FTS, and eligible chunks use only Ollama model `qwen3-embedding:4b` for embeddings.

**Independent Test**: Index image, PDF, and Office fixtures with unique generated tokens, search by those tokens, and assert every eligible embedding request targets Ollama `qwen3-embedding:4b`.

### Tests for User Story 3 (MANDATORY)

- [x] T056 [P] [US3] Add generated image description storage and FTS search tests in `LocalLens/LocalLensTests/SearchTests/GeneratedContentFTSSearchTests.swift`
- [x] T057 [P] [US3] Add generated PDF summary storage and FTS search tests in `LocalLens/LocalLensTests/SearchTests/GeneratedContentFTSSearchTests.swift`
- [x] T058 [P] [US3] Add Office summary storage and FTS search tests in `LocalLens/LocalLensTests/SearchTests/GeneratedContentFTSSearchTests.swift`
- [x] T059 [P] [US3] Add fixed Ollama embedding route tests in `LocalLens/LocalLensTests/SearchTests/FixedOllamaEmbeddingRouteTests.swift`
- [x] T060 [P] [US3] Add missing `qwen3-embedding:4b` partial/failure tests in `LocalLens/LocalLensTests/IndexingTests/EmbeddingReadinessFailureTests.swift`
- [x] T061 [P] [US3] Add generated content delete-index and rebuild-index retention tests in `LocalLens/LocalLensTests/PrivacySecurityTests/GeneratedContentRetentionTests.swift`
- [x] T062 [P] [US3] Add Office short-summary Hermes Agent route regression tests in `LocalLens/LocalLensTests/IndexingTests/OfficeGeneratedSummaryIndexingTests.swift`

### Implementation for User Story 3

- [x] T063 [US3] Persist generated content records after successful image/PDF/Office enrichment in `LocalLens/LocalLens/Indexing/IndexCoordinator.swift`
- [x] T064 [US3] Convert generated content records into searchable generated chunks in `LocalLens/LocalLens/Indexing/GeneratedContentChunkBuilder.swift`
- [x] T065 [US3] Merge generated content chunks into the existing asset chunk list in `LocalLens/LocalLens/Indexing/SearchableChunkBuilder.swift`
- [x] T066 [US3] Insert generated image, PDF, and Office text into FTS rows in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T067 [US3] Add generated-content match reasons and ranking weights in `LocalLens/LocalLens/Search/SearchRanker.swift`
- [x] T068 [US3] Build safe snippets for generated description and summary matches in `LocalLens/LocalLens/Search/SnippetBuilder.swift`
- [x] T069 [US3] Ensure search loads generated text FTS matches with asset and folder context in `LocalLens/LocalLens/Search/SearchService.swift`
- [x] T070 [US3] Force embedding provider to Ollama with model `qwen3-embedding:4b` in `LocalLens/LocalLens/Indexing/EmbeddingStageService.swift`
- [x] T071 [US3] Exclude audio/video chunk types from embedding requests in `LocalLens/LocalLens/Indexing/EmbeddingStageService.swift`
- [x] T072 [US3] Store fixed embedding model metadata for successful vectors in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T073 [US3] Update Office extraction to request and parse short summary output through Hermes Agent in `LocalLens/LocalLens/Extractors/OfficeDocumentExtractor.swift`
- [x] T074 [US3] Update delete-index and rebuild-index cleanup for generated records, chunks, FTS rows, and embeddings in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T075 [US3] Update semantic search vector lookup to respect fixed embedding model metadata in `LocalLens/LocalLens/Search/SemanticVectorStore.swift`
- [x] T076 [US3] Verify User Story 3 with targeted storage, search, indexing, and embedding tests in `specs/003-ai-provider-indexing/quickstart.md`

**Checkpoint**: Generated descriptions/summaries are locally stored, searchable, and embedded only through the fixed Ollama route.

---

## Phase 6: User Story 4 - Exclude audio and video from AI-provider prompting (Priority: P2)

**Goal**: New audio and video indexing work never prompts AI providers for transcription, description, classification, summarization, or embeddings.

**Independent Test**: Index audio and video fixtures with request capture enabled and confirm zero chat or embedding provider requests while deterministic local metadata may still be recorded.

### Tests for User Story 4 (MANDATORY)

- [x] T077 [P] [US4] Add audio no-provider-request indexing tests in `LocalLens/LocalLensTests/IndexingTests/AudioVideoNoAIProviderIndexingTests.swift`
- [x] T078 [P] [US4] Add video no-provider-request indexing tests in `LocalLens/LocalLensTests/IndexingTests/AudioVideoNoAIProviderIndexingTests.swift`
- [x] T079 [P] [US4] Add audio/video source mutation guard tests for provider-skip indexing in `LocalLens/LocalLensTests/PrivacySecurityTests/AudioVideoSourceMutationGuardTests.swift`
- [x] T080 [P] [US4] Add diagnostics tests for skipped audio/video provider stages without raw content in `LocalLens/LocalLensTests/DiagnosticsTests/AudioVideoProviderSkipDiagnosticsTests.swift`

### Implementation for User Story 4

- [x] T081 [US4] Remove provider chat and embedding route scheduling for audio assets in `LocalLens/LocalLens/Indexing/IndexCoordinator.swift`
- [x] T082 [US4] Remove provider chat and embedding route scheduling for video assets in `LocalLens/LocalLens/Indexing/IndexCoordinator.swift`
- [x] T083 [US4] Guard embedding batches against audio/video-derived chunks in `LocalLens/LocalLens/Indexing/EmbeddingStageService.swift`
- [x] T084 [US4] Record safe diagnostic skip state for audio/video provider-backed stages in `LocalLens/LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [x] T085 [US4] Update audio extractor integration to expose deterministic local metadata only in `LocalLens/LocalLens/Extractors/AudioTranscriptExtractor.swift`
- [x] T086 [US4] Update video extractor integration to expose deterministic local metadata only in `LocalLens/LocalLens/Extractors/VideoSceneExtractor.swift`
- [x] T087 [US4] Verify User Story 4 with targeted audio/video indexing tests in `specs/003-ai-provider-indexing/quickstart.md`

**Checkpoint**: Audio/video provider prompting is blocked and independently testable.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, diagnostics quality, and project verification across all stories.

- [x] T088 [P] Update developer-facing implementation notes for AI provider indexing in `specs/003-ai-provider-indexing/quickstart.md`
- [x] T089 [P] Update relevant privacy and diagnostics documentation in `LocalLens/LocalLens/Diagnostics/PrivacyAudit.swift`
- [x] T090 [P] Run prompt-injection and redaction review against `LocalLens/LocalLens/Inference/PromptTemplates.swift` and `LocalLens/LocalLens/Diagnostics/RedactionPolicy.swift`
- [x] T091 Run targeted XCTest suites for inference, indexing, storage, search, diagnostics, and UI in `LocalLens/LocalLens.xcodeproj/project.pbxproj`
- [x] T092 Run full XCTest suite with XCodeMCP first and xcodebuild fallback only for actionable logs in `LocalLens/LocalLens.xcodeproj/project.pbxproj`
- [x] T093 Run final XCodeMCP build verification for the LocalLens scheme in `LocalLens/LocalLens.xcodeproj/project.pbxproj`
- [x] T094 Verify no source fixture file size or modification date changed during tests in `LocalLens/LocalLensTests/Fixtures/AIProviderIndexing/README.md`
- [x] T095 Review git diff for credentials, raw prompts, raw provider responses, full paths, and generated-text leakage in `LocalLens/LocalLens/Diagnostics/RedactionPolicy.swift`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Story 1 (Phase 3, P1 MVP)**: Depends on Foundational; delivers preferred provider selection and image/PDF one-provider routing.
- **User Story 2 (Phase 4, P1)**: Depends on Foundational; can run in parallel with User Story 1 after shared readiness service contracts stabilize.
- **User Story 3 (Phase 5, P2)**: Depends on Foundational and benefits from User Story 1 routing primitives plus User Story 2 readiness UI, but remains independently testable through injected services.
- **User Story 4 (Phase 6, P2)**: Depends on Foundational and embedding route guardrails; can run in parallel with User Story 3 after `EmbeddingStageService` contracts are agreed.
- **Polish (Final Phase)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1**: Independent MVP after Foundational; no dependency on US2, US3, or US4.
- **US2**: Independent Settings/readiness increment after Foundational; no dependency on US3 or US4.
- **US3**: Depends on shared generated content and routing infrastructure; should preserve US1 and US2 behavior.
- **US4**: Depends on shared route guardrails and embedding exclusion decisions; should preserve deterministic local audio/video indexing.

### Within Each User Story

- Tests must be written and fail before implementation.
- Storage/model changes before services.
- Services before indexing integration.
- Indexing integration before search/UI validation.
- Diagnostics and redaction validation before final story checkpoint.

---

## Parallel Opportunities

- Setup tasks T002 through T006 can run in parallel after T001.
- Foundation tests T013, T016, and T019 can run in parallel with service skeletons T014, T015, and T018.
- US1 test tasks T022 through T026 can run in parallel.
- US2 test tasks T039 through T044 can run in parallel.
- US3 test tasks T056 through T062 can run in parallel.
- US4 test tasks T077 through T080 can run in parallel.
- US1 and US2 can proceed in parallel after Foundational because they focus on routing and Settings UI respectively.
- US3 and US4 can proceed in parallel after embedding route contracts are stable, with coordination around `LocalLens/LocalLens/Indexing/EmbeddingStageService.swift`.

---

## Parallel Example: User Story 1

```bash
Task: "T022 Add preferred provider persistence tests in LocalLens/LocalLensTests/InferenceTests/PreferredAIProviderSelectionTests.swift"
Task: "T023 Add image preferred-provider routing request tests in LocalLens/LocalLensTests/PrivacySecurityTests/ImagePreferredProviderRoutingTests.swift"
Task: "T024 Add PDF preferred-provider routing request tests in LocalLens/LocalLensTests/PrivacySecurityTests/PDFPreferredProviderRoutingTests.swift"
Task: "T025 Add no-fallback failure tests in LocalLens/LocalLensTests/InferenceTests/PreferredProviderFailureTests.swift"
```

## Parallel Example: User Story 2

```bash
Task: "T039 Add no-enable-toggle UI test in LocalLens/LocalLensUITests/SettingsAIProviderReadinessUITests.swift"
Task: "T040 Add Hermes profile required-state UI test in LocalLens/LocalLensUITests/SettingsHermesProfileSelectionUITests.swift"
Task: "T041 Add Ollama and oMLX model UI tests in LocalLens/LocalLensUITests/SettingsProviderModelSelectionUITests.swift"
Task: "T044 Add provider readiness service tests in LocalLens/LocalLensTests/InferenceTests/ProviderReadinessServiceTests.swift"
```

## Parallel Example: User Story 3

```bash
Task: "T056 Add generated image FTS tests in LocalLens/LocalLensTests/SearchTests/GeneratedContentFTSSearchTests.swift"
Task: "T059 Add fixed Ollama embedding route tests in LocalLens/LocalLensTests/SearchTests/FixedOllamaEmbeddingRouteTests.swift"
Task: "T061 Add generated content retention tests in LocalLens/LocalLensTests/PrivacySecurityTests/GeneratedContentRetentionTests.swift"
Task: "T062 Add Office summary route tests in LocalLens/LocalLensTests/IndexingTests/OfficeGeneratedSummaryIndexingTests.swift"
```

## Parallel Example: User Story 4

```bash
Task: "T077 Add audio no-provider-request tests in LocalLens/LocalLensTests/IndexingTests/AudioVideoNoAIProviderIndexingTests.swift"
Task: "T078 Add video no-provider-request tests in LocalLens/LocalLensTests/IndexingTests/AudioVideoNoAIProviderIndexingTests.swift"
Task: "T079 Add source mutation guard tests in LocalLens/LocalLensTests/PrivacySecurityTests/AudioVideoSourceMutationGuardTests.swift"
Task: "T080 Add provider skip diagnostics tests in LocalLens/LocalLensTests/DiagnosticsTests/AudioVideoProviderSkipDiagnosticsTests.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundational storage, prompt, readiness, routing, and diagnostics primitives.
3. Complete Phase 3 User Story 1.
4. Stop and validate preferred provider persistence plus one-provider image/PDF enrichment.
5. Demo by selecting a preferred provider and indexing one image plus one PDF.

### Incremental Delivery

1. Deliver US1 for preferred provider selection and one-provider image/PDF routing.
2. Deliver US2 for no-toggle Settings readiness and mandatory profile/model selection.
3. Deliver US3 for searchable generated descriptions/summaries and fixed Ollama embeddings.
4. Deliver US4 for zero AI-provider requests on audio/video new indexing.
5. Complete polish, redaction review, full tests, and XCodeMCP build verification.

### Validation Gates

- Each story requires targeted XCTest or UI tests before implementation.
- Each story checkpoint must update `specs/003-ai-provider-indexing/quickstart.md` with actual verification evidence.
- Final verification must include targeted tests, full tests, source non-mutation checks, redaction checks, and XCodeMCP build success.
