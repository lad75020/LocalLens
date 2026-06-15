# Feature Specification: Office Indexing and Provider Settings

**Feature Branch**: `002-office-provider-settings`

**Created**: 2026-06-16

**Status**: Draft

**Input**: User description: "In settings allow the user to request indexing of pptx, docx and xlsx files, for the Hermes Agent provider only. The prompt contains « Use the /pptx skill » or « Use the /docx skill » or « Use the /xlsx skill » in those respective cases. For OLLAMA and oMLX providers, allow the user to choose the AI model in Settings window. That model is then used to call the inference API. For Hermes Agent provider, allow the user to select the profile used during inference, among those reported available by the API."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable Office document indexing through Hermes Agent (Priority: P1)

A user configures LocalLens to index PowerPoint, Word, and Excel documents only through the Hermes Agent provider so those documents become part of the private searchable library using the matching Hermes document skills.

**Why this priority**: Office documents are explicitly requested new content types, and limiting them to Hermes Agent preserves a safe, skill-aware processing path instead of sending document content to providers that do not understand the required document workflows.

**Independent Test**: Can be fully tested by enabling Office indexing in Settings, selecting the Hermes Agent provider, adding a folder with `.pptx`, `.docx`, and `.xlsx` files, and confirming each selected document type is queued for indexing with the correct skill directive while source files remain unchanged.

**Acceptance Scenarios**:

1. **Given** Hermes Agent is enabled and Office document indexing is enabled for `.pptx`, **When** a watched folder contains a PowerPoint file, **Then** LocalLens queues that file for Hermes Agent indexing and includes the literal directive `Use the /pptx skill` in the provider request.
2. **Given** Hermes Agent is enabled and Office document indexing is enabled for `.docx`, **When** a watched folder contains a Word document, **Then** LocalLens queues that file for Hermes Agent indexing and includes the literal directive `Use the /docx skill` in the provider request.
3. **Given** Hermes Agent is enabled and Office document indexing is enabled for `.xlsx`, **When** a watched folder contains an Excel workbook, **Then** LocalLens queues that file for Hermes Agent indexing and includes the literal directive `Use the /xlsx skill` in the provider request.
4. **Given** Hermes Agent is disabled or unavailable, **When** Office document indexing options are viewed, **Then** LocalLens clearly indicates that Office document indexing requires Hermes Agent and does not route those files to Ollama, oMLX, or custom remote providers.

---

### User Story 2 - Choose models for local loopback providers (Priority: P1)

A user selects which AI model LocalLens should use for Ollama and oMLX inference from Settings so indexing and semantic processing use the intended local model.

**Why this priority**: Users may have multiple local models with different quality, speed, and privacy characteristics; choosing the model is required for predictable provider behavior.

**Independent Test**: Can be fully tested by selecting different available models for Ollama and oMLX in Settings, running a provider-backed indexing or inference operation, and confirming the selected model name is the model used for the provider request.

**Acceptance Scenarios**:

1. **Given** Ollama reports one or more available models, **When** the user opens Settings, **Then** LocalLens shows a model selection control for Ollama.
2. **Given** oMLX reports one or more available models, **When** the user opens Settings, **Then** LocalLens shows a model selection control for oMLX.
3. **Given** the user selects a model for Ollama or oMLX, **When** LocalLens later calls that provider for inference, **Then** the request uses the selected model.
4. **Given** the previously selected model is no longer available, **When** Settings refreshes provider state, **Then** LocalLens prompts the user to choose another model or marks provider-backed inference as not ready.

---

### User Story 3 - Choose Hermes Agent profile for inference (Priority: P2)

A user selects which Hermes Agent profile LocalLens should use for Hermes Agent inference so document indexing and other Hermes-backed processing run under the intended profile configuration.

**Why this priority**: Hermes profiles may have different models, providers, skills, and privacy settings; selecting the profile gives users control over which Hermes environment performs LocalLens inference.

**Independent Test**: Can be fully tested by exposing multiple Hermes Agent profiles from the provider, choosing one in Settings, running a Hermes-backed indexing operation, and confirming the selected profile is used for that operation.

**Acceptance Scenarios**:

1. **Given** Hermes Agent reports available profiles, **When** the user opens Settings, **Then** LocalLens shows those profiles in a selectable list.
2. **Given** the user selects a Hermes Agent profile, **When** LocalLens later calls Hermes Agent for inference, **Then** the selected profile is used for the request.
3. **Given** the selected Hermes profile is no longer reported, **When** Settings refreshes profile state, **Then** LocalLens marks the selected profile as unavailable and requires a valid selection before Hermes-backed Office indexing starts.
4. **Given** no profile has been selected yet, **When** Hermes Agent is available, **Then** LocalLens uses a clearly displayed default profile selection rather than silently choosing a hidden profile.

---

### Edge Cases

- Hermes Agent is enabled but reports no profiles or the profile list cannot be loaded.
- Ollama or oMLX is enabled but reports no models or the model list cannot be loaded.
- A selected provider model or Hermes profile disappears between Settings configuration and an indexing run.
- A folder contains Office documents while Hermes Agent is disabled, unhealthy, missing required profile selection, or explicitly not selected for Office indexing.
- A folder contains both currently supported media files and Office files; media files continue through their existing indexing path while Office files follow only the Hermes Agent path.
- A user disables an Office file type after files of that type were already queued but before indexing begins.
- Office document content includes prompt-injection text or instructions; LocalLens treats document contents as untrusted input and preserves the required skill directive and privacy constraints.
- Office documents are very large, corrupted, password protected, macro-enabled, or unreadable; LocalLens records safe failures and continues indexing other files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to enable or disable indexing requests for `.pptx`, `.docx`, and `.xlsx` files independently in Settings.
- **FR-002**: The system MUST restrict `.pptx`, `.docx`, and `.xlsx` indexing to the Hermes Agent provider only.
- **FR-003**: The system MUST NOT send `.pptx`, `.docx`, or `.xlsx` file bytes, extracted text, prompts, metadata, or embeddings to Ollama, oMLX, or custom remote providers for Office document indexing.
- **FR-004**: When requesting `.pptx` indexing through Hermes Agent, the system MUST include the literal directive `Use the /pptx skill` in the prompt.
- **FR-005**: When requesting `.docx` indexing through Hermes Agent, the system MUST include the literal directive `Use the /docx skill` in the prompt.
- **FR-006**: When requesting `.xlsx` indexing through Hermes Agent, the system MUST include the literal directive `Use the /xlsx skill` in the prompt.
- **FR-007**: The system MUST treat Office document content as untrusted data and keep system, privacy, and skill-use instructions separate from document content in any user-visible or provider-facing prompt representation.
- **FR-008**: Users MUST be able to view available Ollama models in Settings when Ollama is enabled and reachable.
- **FR-009**: Users MUST be able to choose one Ollama model in Settings for LocalLens inference.
- **FR-010**: The system MUST use the selected Ollama model for subsequent Ollama inference requests.
- **FR-011**: Users MUST be able to view available oMLX models in Settings when oMLX is enabled and reachable.
- **FR-012**: Users MUST be able to choose one oMLX model in Settings for LocalLens inference.
- **FR-013**: The system MUST use the selected oMLX model for subsequent oMLX inference requests.
- **FR-014**: Users MUST be able to view Hermes Agent profiles reported by the Hermes Agent provider in Settings.
- **FR-015**: Users MUST be able to choose one Hermes Agent profile in Settings for LocalLens Hermes-backed inference.
- **FR-016**: The system MUST use the selected Hermes Agent profile for subsequent Hermes Agent inference requests.
- **FR-017**: The system MUST persist selected Office indexing options, selected Ollama model, selected oMLX model, and selected Hermes Agent profile across app restarts.
- **FR-018**: The system MUST clearly show unavailable, stale, or missing provider model/profile selections before starting provider-backed indexing.
- **FR-019**: The system MUST record safe, retryable failures for Office document indexing when Hermes Agent is unavailable, a selected profile is unavailable, the file is unreadable, or the operation is cancelled.
- **FR-020**: Existing indexing, search, progress, retry, cancel, and failure-dashboard flows MUST include Office document jobs without changing source files.
- **FR-021**: Search results for indexed Office documents MUST identify the original file name, document type, folder context, match reason, and a safe snippet or summary when available.

### Constitutional Requirements *(mandatory for file-system or AI features)*

- **CA-001 File Authority**: This feature reads user-selected watched folders and Office file types `.pptx`, `.docx`, and `.xlsx` for indexing and search metadata generation. It writes only LocalLens-controlled index records, derived text or summaries, job state, settings, failures, and diagnostics. It MUST NOT write, rename, move, delete, repair, convert in place, or otherwise modify source Office documents.
- **CA-002 Local/Remote AI**: Office document indexing is Hermes Agent-only. Hermes Agent may use the user-selected Hermes profile configuration, but LocalLens must present this as an explicit provider path in Settings. Ollama and oMLX remain local loopback providers for non-Office inference and use the user-selected model. Custom remote providers remain excluded from Office document indexing.
- **CA-003 Privacy & Retention**: LocalLens stores Office-derived searchable text, summaries, match metadata, embeddings where applicable, indexing status, provider selection settings, and safe failures in local app-controlled storage. Users can delete or rebuild local index data using the existing privacy and storage controls.
- **CA-004 Non-Destructive Guarantee**: Source Office files remain unmodified during discovery, indexing, retry, cancellation, search, diagnostics, and result actions.
- **CA-005 Failure & Recovery**: The system must provide safe behavior for denied folder access, stale authorization, missing Office files, unsupported or corrupted documents, password-protected documents, provider unavailability, missing selected model/profile, cancellation, app restart, and index corruption. Recovery actions include retry, ignore, reauthorize, cancel, reindex, delete index, or rebuild index where applicable.
- **CA-006 Performance Bounds**: Office document indexing must run as bounded background work, must not block Settings or search interactions, and should surface progress within 2 seconds of an Office job starting. Very large Office files may be skipped or partially indexed with a safe failure rather than exhausting memory.
- **CA-007 Observability**: Settings and diagnostics must show provider readiness, selected model/profile state, Office queue progress, failure categories, and retryability without exposing raw document content, prompts, credentials, full paths, or full extracted text by default.

### Key Entities *(include if feature involves data)*

- **Office Indexing Preference**: User setting for whether `.pptx`, `.docx`, and `.xlsx` files are eligible for Hermes Agent indexing.
- **Provider Model Selection**: Persisted selected model for a local provider such as Ollama or oMLX, including availability state and last refresh time.
- **Hermes Profile Selection**: Persisted selected Hermes Agent profile, including display name, identifier, availability state, and last refresh time.
- **Office Index Job**: Queue item representing an Office document indexing request, including file type, provider requirement, safe progress state, retryability, and cancellation state.
- **Office Extraction Record**: Local derived record for an Office document, including stage status, safe summary, searchable text or snippets, provider/profile used, and redacted failure information.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can enable Office indexing for each requested document type from Settings in under 60 seconds.
- **SC-002**: 100% of queued `.pptx`, `.docx`, and `.xlsx` Office indexing requests are routed only to Hermes Agent and include the required matching skill directive.
- **SC-003**: 0 Office document indexing requests are routed to Ollama, oMLX, or custom remote providers.
- **SC-004**: A user can select and persist an Ollama model and an oMLX model from Settings, and subsequent provider-backed inference uses the selected model in every request.
- **SC-005**: A user can select and persist a Hermes Agent profile from Settings, and subsequent Hermes-backed inference uses that selected profile in every request.
- **SC-006**: If a selected model or profile becomes unavailable, Settings shows the unavailable state before any new provider-backed indexing starts.
- **SC-007**: Office document indexing failures are visible in the failure dashboard with safe categories and recovery actions, without exposing full document content or full paths.
- **SC-008**: Existing supported media indexing continues to work when Office indexing is disabled, when Hermes Agent is unavailable, or when Office documents fail.

## Assumptions

- Office document indexing is optional and disabled per file type until the user enables it in Settings.
- Hermes Agent is considered the only provider with the required document-specific skills for `.pptx`, `.docx`, and `.xlsx` processing.
- The selected Ollama or oMLX model applies to provider-backed LocalLens inference for that provider until changed by the user or marked unavailable.
- The selected Hermes Agent profile applies to all Hermes Agent-backed LocalLens inference until changed by the user or marked unavailable.
- When provider model/profile discovery fails, LocalLens preserves the last selected value but marks it as not currently verified.
- Existing source-file non-mutation, local index deletion, and rebuild controls remain the governing privacy and retention behavior.
