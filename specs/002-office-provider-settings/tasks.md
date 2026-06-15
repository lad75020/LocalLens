# Tasks: Office Indexing and Provider Settings

**Input**: Design documents from `/specs/002-office-provider-settings/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`
**Tests**: Tests are MANDATORY for LocalLens features. Write story tests first and confirm they fail before implementation.
**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files or only adds tests/fixtures.
- **[Story]**: User story label for story phases only.
- Every task names exact production, test, fixture, project, or documentation paths.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare fixtures, project structure, and validation references shared by all stories.

- [X] T001 [P] Add small non-sensitive Office fixture placeholders and checksum notes in `LocalLensTests/Fixtures/Office/README.md`
- [X] T002 [P] Add prompt-injection Office fixture text samples in `LocalLensTests/Fixtures/Office/PromptInjectionFixtures.swift`
- [X] T003 [P] Register new Office/provider test file groups in `project.yml` and `LocalLens.xcodeproj/project.pbxproj`
- [X] T004 [P] Add feature validation references from `specs/002-office-provider-settings/quickstart.md` to `LocalLensTests/Fixtures/Office/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared domain, storage, and service boundaries that block all user stories.

**CRITICAL**: No user-story implementation can start until this phase is complete.

- [X] T005 Add Office media and selection state enums in `LocalLens/Storage/Models/DomainEnums.swift`
- [X] T006 Add Office preference, provider model selection, Hermes profile selection, and profile summary models in `LocalLens/Storage/Models/LocalLensModels.swift`
- [X] T007 Add provider selection and Office preference repository contracts in `LocalLens/Storage/Repositories/RepositoryProtocols.swift`
- [X] T008 Add SQLite migration for Office preferences, selected provider models, Hermes profiles, and Office extraction metadata in `LocalLens/Storage/Migrations/MigrationV1.swift`
- [X] T009 Implement SQLite persistence for Office preferences and provider/profile selections in `LocalLens/Storage/Repositories/SQLiteRepositories.swift`
- [X] T010 [P] Add migration and persistence tests for Office/provider settings in `LocalLensTests/StorageTests/OfficeProviderSettingsStorageTests.swift`
- [X] T011 [P] Create provider selection availability value types and request metadata helpers in `LocalLens/Inference/ProviderSelectionService.swift`
- [X] T012 Wire Office/provider selection repositories and services in `LocalLens/Support/DependencyContainer.swift`
- [X] T013 Extend diagnostic redaction for Office prompts, provider bodies, model/profile errors, and raw document text in `LocalLens/Diagnostics/RedactionPolicy.swift`
- [X] T014 [P] Add redaction tests for Office prompts and selected provider/profile diagnostics in `LocalLensTests/DiagnosticsTests/OfficeProviderRedactionTests.swift`

**Checkpoint**: Foundation ready; US1 and US2 can start in parallel, and US3 can start after shared profile selection models exist.

---

## Phase 3: User Story 1 - Enable Office document indexing through Hermes Agent (Priority: P1) MVP

**Goal**: Users can enable `.pptx`, `.docx`, and `.xlsx` indexing in Settings, and LocalLens routes those files only through Hermes Agent with the matching skill directive while source files remain unchanged.

**Independent Test**: Enable Office indexing with a stubbed ready Hermes provider, index a watched folder containing `.pptx`, `.docx`, and `.xlsx`, verify Hermes-only queued jobs/prompts/search snippets/failures, and verify Office source bytes are unchanged.

### Tests for User Story 1 (MANDATORY)

- [X] T015 [P] [US1] Add `MediaTypeResolver` tests for `.pptx`, `.docx`, and `.xlsx` eligibility in `LocalLensTests/MediaDiscoveryTests/OfficeMediaTypeResolverTests.swift`
- [X] T016 [P] [US1] Add Office discovery gating tests for disabled toggles and unavailable Hermes readiness in `LocalLensTests/MediaDiscoveryTests/OfficeDiscoveryPolicyTests.swift`
- [X] T017 [P] [US1] Add prompt directive and injection-resistance tests for `/pptx`, `/docx`, and `/xlsx` prompts in `LocalLensTests/InferenceTests/OfficePromptTemplatesTests.swift`
- [X] T018 [P] [US1] Add Hermes-only routing tests that fail if Ollama, oMLX, or custom providers receive Office content in `LocalLensTests/PrivacySecurityTests/OfficeProviderRoutingTests.swift`
- [X] T019 [P] [US1] Add Office indexing pipeline tests for queue, progress, cancellation, retry, and safe failures in `LocalLensTests/IndexingTests/OfficeIndexingPipelineTests.swift`
- [X] T020 [P] [US1] Add Office source non-mutation tests for index, retry, cancel, ignore, and rebuild flows in `LocalLensTests/PrivacySecurityTests/OfficeSourceMutationGuardTests.swift`
- [X] T021 [P] [US1] Add Settings Office toggle UI tests with accessibility identifiers in `LocalLensUITests/SettingsOfficeIndexingUITests.swift`

### Implementation for User Story 1

- [X] T022 [US1] Extend Office file type resolution and content type mapping in `LocalLens/MediaDiscovery/MediaTypeResolver.swift`
- [X] T023 [US1] Add Office discovery policy input and toggle-aware queue gating in `LocalLens/MediaDiscovery/MediaDiscoveryService.swift`
- [X] T024 [US1] Implement Office prompt builders with required skill directives and untrusted data sections in `LocalLens/Inference/PromptTemplates.swift`
- [X] T025 [US1] Create Hermes-only Office extraction service in `LocalLens/Extractors/OfficeDocumentExtractor.swift`
- [X] T026 [US1] Extend Office job dispatch, cancellation, retry, and safe failure mapping in `LocalLens/Indexing/IndexCoordinator.swift`
- [X] T027 [US1] Drain Office jobs through Hermes-only extraction in `LocalLens/Indexing/IndexingPipelineRunner.swift`
- [X] T028 [US1] Build Office searchable chunks, summaries, document-type labels, and match reasons in `LocalLens/Indexing/SearchableChunkBuilder.swift`
- [X] T029 [US1] Include Office document result labels and safe snippets in `LocalLens/Search/SearchResultViewModel.swift`
- [X] T030 [US1] Add Office indexing toggles, Hermes-required readiness copy, and accessibility identifiers in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T031 [US1] Surface Office failures and recovery actions in `LocalLens/Diagnostics/FailureDashboardView.swift`
- [X] T032 [US1] Include Office preference state in redacted diagnostics without raw content in `LocalLens/Diagnostics/DiagnosticExporter.swift`
- [X] T033 [US1] Wire Office extractor, prompt builder, and discovery policy dependencies in `LocalLens/Support/DependencyContainer.swift`
- [X] T034 [US1] Validate US1 independently with targeted XCodeMCP tests listed in `specs/002-office-provider-settings/quickstart.md`

**Checkpoint**: Office indexing MVP is functional and independently testable without implementing local model pickers or configurable Hermes profile UI.

---

## Phase 4: User Story 2 - Choose models for local loopback providers (Priority: P1)

**Goal**: Users can choose Ollama and oMLX models in Settings, and subsequent provider-backed inference uses the selected local model instead of an implicit first model.

**Independent Test**: Stub Ollama/oMLX `/models`, select different models in Settings, run provider-backed inference, and verify requests use the selected model while stale/missing selections block new provider-backed work.

### Tests for User Story 2 (MANDATORY)

- [X] T035 [P] [US2] Add Ollama and oMLX model discovery parsing tests in `LocalLensTests/InferenceTests/ProviderModelDiscoveryTests.swift`
- [X] T036 [P] [US2] Add selected model persistence and stale model tests in `LocalLensTests/InferenceTests/ProviderModelSelectionTests.swift`
- [X] T037 [P] [US2] Add embedding/chat request tests that assert selected Ollama and oMLX model IDs in `LocalLensTests/InferenceTests/OpenAICompatibleClientModelSelectionTests.swift`
- [X] T038 [P] [US2] Add Settings model picker UI tests for Ollama and oMLX in `LocalLensUITests/SettingsProviderModelSelectionUITests.swift`

### Implementation for User Story 2

- [X] T039 [US2] Implement asynchronous Ollama and oMLX model refresh, timeout, stale selection, and safe error handling in `LocalLens/Inference/ProviderSelectionService.swift`
- [X] T040 [US2] Use selected provider model IDs for embeddings and inference instead of `modelIDs[0]` in `LocalLens/Indexing/EmbeddingStageService.swift`
- [X] T041 [US2] Add selected-model parameters to OpenAI-compatible embeddings and chat requests in `LocalLens/Inference/OpenAICompatibleClient.swift`
- [X] T042 [US2] Persist selected Ollama and oMLX models from Settings actions in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T043 [US2] Add Ollama and oMLX model pickers, stale warnings, and accessibility identifiers in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T044 [US2] Include selected local model readiness in provider diagnostics without credentials or raw bodies in `LocalLens/Diagnostics/DiagnosticExporter.swift`
- [X] T045 [US2] Validate US2 independently with targeted provider selection tests listed in `specs/002-office-provider-settings/quickstart.md`

**Checkpoint**: Local provider model selection is functional and independently testable with stubbed Ollama/oMLX providers.

---

## Phase 5: User Story 3 - Choose Hermes Agent profile for inference (Priority: P2)

**Goal**: Users can choose a Hermes Agent profile reported by the API, and Hermes-backed inference uses that selected profile with stale/unavailable states blocking Office indexing.

**Independent Test**: Stub Hermes profile discovery, select a profile in Settings, run a Hermes-backed Office indexing request, verify profile request metadata is sent, and verify stale profiles block new Office work.

### Tests for User Story 3 (MANDATORY)

- [X] T046 [P] [US3] Add Hermes profile discovery parsing and alternate field-name tests in `LocalLensTests/InferenceTests/HermesProfileDiscoveryTests.swift`
- [X] T047 [P] [US3] Add selected Hermes profile persistence, default initialization, and stale profile tests in `LocalLensTests/InferenceTests/HermesProfileSelectionTests.swift`
- [X] T048 [P] [US3] Add Hermes request metadata tests that keep model as `hermes-agent` and send selected profile control in `LocalLensTests/InferenceTests/HermesProfileRequestTests.swift`
- [X] T049 [P] [US3] Add Settings Hermes profile picker UI tests in `LocalLensUITests/SettingsHermesProfileSelectionUITests.swift`

### Implementation for User Story 3

- [X] T050 [US3] Implement Hermes Agent profile discovery, timeout, compatibility parsing, and stale profile state in `LocalLens/Inference/ProviderSelectionService.swift`
- [X] T051 [US3] Add selected Hermes profile request metadata support in `LocalLens/Inference/OpenAICompatibleClient.swift`
- [X] T052 [US3] Apply selected Hermes profile to Office extraction requests in `LocalLens/Extractors/OfficeDocumentExtractor.swift`
- [X] T053 [US3] Add Hermes profile picker, default profile display, stale warnings, and accessibility identifier in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T054 [US3] Block new Hermes-backed Office jobs when selected profile is unavailable in `LocalLens/Indexing/IndexingPipelineRunner.swift`
- [X] T055 [US3] Include selected Hermes profile summary and stale state in redacted diagnostics in `LocalLens/Diagnostics/DiagnosticExporter.swift`
- [X] T056 [US3] Validate US3 independently with targeted Hermes profile tests listed in `specs/002-office-provider-settings/quickstart.md`

**Checkpoint**: Hermes profile selection is functional and independently testable, and Office indexing uses the selected profile.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, accessibility, performance, and release readiness across all stories.

- [X] T057 [P] Update developer validation notes for Office/provider settings in `specs/002-office-provider-settings/quickstart.md`
- [X] T058 [P] Add accessibility labels and VoiceOver audit fixes for new Settings controls in `LocalLens/AppShell/SettingsWindow.swift`
- [X] T059 [P] Add performance coverage for provider refresh under five seconds and Office job progress within two seconds in `LocalLensTests/IndexingTests/OfficeProviderPerformanceTests.swift`
- [X] T060 [P] Add privacy audit coverage for Office diagnostics, provider routing, and selected profile/model metadata in `LocalLensTests/PrivacySecurityTests/OfficeProviderPrivacyAuditTests.swift`
- [X] T061 Run the full LocalLens XCTest suite with XCodeMCP and record results in `specs/002-office-provider-settings/quickstart.md`
- [X] T062 Build LocalLens with XCodeMCP and record build output in `specs/002-office-provider-settings/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 Office indexing (Phase 3)**: Depends on Foundation; MVP scope.
- **US2 local model selection (Phase 4)**: Depends on Foundation; can run in parallel with US1 after shared service boundaries exist.
- **US3 Hermes profile selection (Phase 5)**: Depends on Foundation; integrates with US1 Office extraction once both are available.
- **Polish (Phase 6)**: Depends on all desired user stories.

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational and is MVP; uses stub/default Hermes readiness before configurable profile UI exists.
- **US2 (P1)**: Can start after Foundational and is independently testable with stubbed Ollama/oMLX providers.
- **US3 (P2)**: Can start after Foundational and integrates with US1 by replacing default Hermes readiness with selected profile readiness.

### Within Each User Story

- Write and run the story tests first; confirm they fail before implementation.
- Implement models/storage or service contracts before UI integration.
- Implement request routing before indexing pipeline integration.
- Validate each story independently before starting polish tasks.

### Parallel Opportunities

- Setup tasks T001-T004 can run in parallel.
- Foundational tests and redaction work T010, T011, and T014 can run in parallel with storage implementation once contracts are agreed.
- US1 test tasks T015-T021 can run in parallel before US1 implementation.
- US2 test tasks T035-T038 can run in parallel before US2 implementation.
- US3 test tasks T046-T049 can run in parallel before US3 implementation.
- Polish tasks T057-T060 can run in parallel after the relevant stories are complete.

---

## Parallel Example: User Story 1

```bash
# Launch US1 tests together before implementation:
Task: "T015 [US1] MediaTypeResolver Office tests in LocalLensTests/MediaDiscoveryTests/OfficeMediaTypeResolverTests.swift"
Task: "T016 [US1] Office discovery policy tests in LocalLensTests/MediaDiscoveryTests/OfficeDiscoveryPolicyTests.swift"
Task: "T017 [US1] Office prompt template tests in LocalLensTests/InferenceTests/OfficePromptTemplatesTests.swift"
Task: "T018 [US1] Hermes-only routing tests in LocalLensTests/PrivacySecurityTests/OfficeProviderRoutingTests.swift"
Task: "T019 [US1] Office indexing pipeline tests in LocalLensTests/IndexingTests/OfficeIndexingPipelineTests.swift"
Task: "T020 [US1] Office source mutation guard tests in LocalLensTests/PrivacySecurityTests/OfficeSourceMutationGuardTests.swift"
Task: "T021 [US1] Settings Office UI tests in LocalLensUITests/SettingsOfficeIndexingUITests.swift"
```

## Parallel Example: User Story 2

```bash
# Launch US2 tests together before implementation:
Task: "T035 [US2] Provider model discovery tests in LocalLensTests/InferenceTests/ProviderModelDiscoveryTests.swift"
Task: "T036 [US2] Provider model selection tests in LocalLensTests/InferenceTests/ProviderModelSelectionTests.swift"
Task: "T037 [US2] OpenAI client model selection tests in LocalLensTests/InferenceTests/OpenAICompatibleClientModelSelectionTests.swift"
Task: "T038 [US2] Settings provider model UI tests in LocalLensUITests/SettingsProviderModelSelectionUITests.swift"
```

## Parallel Example: User Story 3

```bash
# Launch US3 tests together before implementation:
Task: "T046 [US3] Hermes profile discovery tests in LocalLensTests/InferenceTests/HermesProfileDiscoveryTests.swift"
Task: "T047 [US3] Hermes profile selection tests in LocalLensTests/InferenceTests/HermesProfileSelectionTests.swift"
Task: "T048 [US3] Hermes profile request tests in LocalLensTests/InferenceTests/HermesProfileRequestTests.swift"
Task: "T049 [US3] Settings Hermes profile UI tests in LocalLensUITests/SettingsHermesProfileSelectionUITests.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup tasks T001-T004.
2. Complete Phase 2 foundational tasks T005-T014.
3. Complete Phase 3 US1 tasks T015-T034.
4. Stop and validate Office indexing independently with the US1 tests and quickstart Office smoke flow in `specs/002-office-provider-settings/quickstart.md`.

### Incremental Delivery

1. Deliver US1 Office indexing MVP with Hermes-only routing and prompt directives.
2. Deliver US2 local provider model selection for Ollama and oMLX.
3. Deliver US3 Hermes profile selection and integrate it with Office indexing readiness.
4. Complete Phase 6 polish and full XCodeMCP build/test verification.

### Validation Gates

- Every story gate requires targeted XCTest/UI/privacy tests to pass for files under `LocalLensTests/` and `LocalLensUITests/`.
- Final gate requires XCodeMCP build and full test run recorded in `specs/002-office-provider-settings/quickstart.md`.
- No source Office file may change during tests; source mutation guards in `LocalLensTests/PrivacySecurityTests/OfficeSourceMutationGuardTests.swift` are release-blocking.
