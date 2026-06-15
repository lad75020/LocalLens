# Research: Office Indexing and Provider Settings

## Decision: Represent Office files with explicit document subtypes

**Decision**: Extend LocalLens domain typing so `.pptx`, `.docx`, and `.xlsx` are distinguishable at indexing and prompt-build time. The preferred implementation is either new `MediaType` cases (`presentation`, `document`, `spreadsheet`) or a dedicated `OfficeDocumentKind` stored on Office-capable assets. The plan recommends explicit subtypes because the prompt directive differs per extension.

**Rationale**:
- The feature has three different required prompt directives.
- Search filters and results should show PowerPoint, Word, and Excel distinctly.
- Failure dashboards need safe, user-understandable file-type categories.

**Alternatives considered**:
- Single `document` media type only: too coarse for prompt construction and Settings toggles.
- Treat Office files as PDFs/text internally: risks accidental non-Hermes routing and poor result labels.

## Decision: Settings-gated Office discovery

**Decision**: Add `.pptx`, `.docx`, and `.xlsx` to supported type resolution only when the matching Office indexing preference is enabled and Hermes Agent is ready enough to queue work. Discovery should continue to count skipped/unsupported files safely when Office indexing is disabled or Hermes is unavailable.

**Rationale**:
- The spec says users request indexing of those types from Settings.
- If type resolution globally accepts Office files before user opt-in, folders could accumulate confusing unsupported jobs.
- Existing media files must continue through current paths regardless of Office state.

**Alternatives considered**:
- Always discover Office files but leave jobs pending: creates stale queues and user confusion.
- Require Hermes health before discovery starts: too strict; existing media discovery should not be blocked by Hermes.

## Decision: Hermes Agent-only Office extraction boundary

**Decision**: Add an `OfficeDocumentExtractor` service that only uses the Hermes Agent provider. It builds a prompt with the required literal skill directive (`Use the /pptx skill`, `Use the /docx skill`, or `Use the /xlsx skill`), document metadata, bounded content/reference payload, and untrusted-content guardrails. No Ollama, oMLX, or custom remote provider is eligible for Office extraction.

**Rationale**:
- The requested skills are Hermes Agent skills, not generic local-model capabilities.
- Keeping a single Office extraction boundary makes routing tests straightforward.
- The service can enforce prompt-safety and redaction consistently.

**Alternatives considered**:
- Reuse generic metadata extraction chat calls: misses required skill directives and profile semantics.
- Invoke local unzip/XML parsing directly for all Office content: useful for future local fallback, but the feature explicitly requests Hermes skill use.

## Decision: Prompt construction separates instructions from untrusted document content

**Decision**: Office prompts use a stable system/developer instruction portion containing privacy and skill-directive rules, then a clearly labeled data section for document metadata/content. Prompt templates must bound text, escape unsafe delimiters, and include injection-resistant language.

**Rationale**:
- Office documents can contain prompt injection text.
- The required skill directive must remain higher-priority than document content.
- Diagnostics must not store raw prompts by default.

**Alternatives considered**:
- Concatenate document text after the skill directive with no structure: easier but injection-prone.
- Ask Hermes to infer the skill from file extension: violates the literal directive requirement.

## Decision: One selected model per local provider

**Decision**: Extend `ProviderSetting` or a companion selection entity with `selectedModelID` for Ollama and oMLX. Settings refreshes available model IDs via provider model discovery, validates the selected model against the latest list, and uses the selected value for embeddings/chat/inference instead of silently using `modelIDs[0]`.

**Rationale**:
- Current code stores discovered model IDs but `EmbeddingStageService` uses the first model.
- Users need predictable local model choice.
- Stale model selections should be visible before indexing starts.

**Alternatives considered**:
- Keep first-model behavior: non-deterministic when providers reorder models.
- Separate selected embedding/chat models now: more flexible but larger scope than requested; can be added later.

## Decision: Provider model discovery is async and non-blocking

**Decision**: Settings model/profile refreshes run asynchronously, apply per-provider timeouts, and update readiness state without blocking the window. Unreachable providers preserve previous selections but mark them unverified/unavailable.

**Rationale**:
- Local endpoints may be stopped or slow.
- Settings should remain responsive and native-feeling.
- Existing privacy diagnostics already expect provider unavailability to be tolerated.

**Alternatives considered**:
- Refresh all providers synchronously before displaying Settings: risks poor UX.
- Clear selections when refresh fails: unnecessarily destructive and frustrating.

## Decision: Hermes profile discovery and selection

**Decision**: Add Hermes profile discovery from the Hermes Agent provider and persist one selected profile identifier. Requests to Hermes Agent include the selected profile through the agreed request control surface (for example a Hermes profile header such as `X-Hermes-Profile`, or the project-standard equivalent if the provider client already centralizes it). The API-server compatibility model remains the advertised Hermes model ID, commonly `hermes-agent`, rather than the profile name.

**Rationale**:
- Hermes profiles can represent different models, providers, skills, and privacy settings.
- Hermes Agent skill guidance warns that API-server `model` is compatibility metadata; profile is separate request context.
- A stale profile must be detected before Office indexing starts.

**Alternatives considered**:
- Use the model field to carry profile names: conflicts with Hermes API-server model semantics.
- Use the active/default Hermes profile only: hides an important user choice.

## Decision: Storage migration preserves existing provider rows

**Decision**: Add schema migration(s) that preserve existing `ProviderSetting` rows while adding selected model/profile/Office preference fields or companion settings rows. Existing users should keep current enabled/automatic provider choices.

**Rationale**:
- The repository already persists provider settings.
- Replacing rows would reset user privacy choices.
- This feature adds settings rather than changing credential storage.

**Alternatives considered**:
- Drop/reseed providers: simple but unsafe for user preferences.
- Encode all new data into generic key/value settings only: flexible but harder to validate in tests.

## Decision: Settings UI uses existing native pane style with restrained material/glass

**Decision**: Add controls inside existing Settings tabs rather than introducing a new window. Office indexing toggles belong in Indexing or AI Providers with clear Hermes-only copy. Ollama/oMLX model pickers and Hermes profile picker belong in AI Providers. Use existing `SettingsPane`, status pills, material cards, accessibility identifiers, keyboard focus, and concise explanatory copy.

**Rationale**:
- The app already has a Settings TabView with Providers/Indexing tabs.
- macOS design guidance favors sparse top-level UI and progressive disclosure.
- Liquid Glass/material should support hierarchy, not reduce readability in dense settings.

**Alternatives considered**:
- New modal for Office indexing: unnecessary extra surface.
- Hide Office options until Hermes is healthy: discoverability suffers; better to show disabled/unavailable state with explanation.
