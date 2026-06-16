# Research: AI Provider Indexing Preferences

## Decision 1: Persist one preferred descriptive provider in app settings

**Decision**: Store a single preferred descriptive provider identifier in local settings, validate it against visible provider rows and readiness state before each image/PDF enrichment stage, and block the affected stage with a safe failure if the provider is missing or not ready.

**Rationale**: The feature requires only one AI provider to be inferred at any time by indexing. A single persisted value avoids provider-order ambiguity and prevents silent fallback that could send image/PDF content to an unintended provider.

**Alternatives considered**:
- Use the first automatic-indexing provider: rejected because provider ordering is implicit and conflicts with explicit user preference.
- Store preferred provider separately per media type: rejected because the requested scope is one preferred provider for image/PDF enrichment.
- Fall back to another provider when preferred provider fails: rejected because it violates the single-provider inference and privacy expectations.

## Decision 2: Replace provider enablement with readiness state in Settings

**Decision**: Provider rows remain visible and configurable by default. Remove the provider-level enable toggle from Settings, migrate default/persisted rows toward always-enabled configuration targets, and show readiness status for transport, credentials, Hermes profile, Ollama model, oMLX model, and fixed embedding model.

**Rationale**: The user explicitly requested all providers always enabled and mandatory profile/model choices. Readiness is a better user model than enablement because it makes the blocker actionable without hiding providers.

**Alternatives considered**:
- Keep enable toggles but default them on: rejected because the UI would still expose a forbidden control.
- Remove `isEnabled` from all storage immediately: rejected for planning because existing code relies on it; an additive compatibility migration can preserve data while UI and routing stop treating it as user-controlled.
- Auto-select the first model/profile silently: rejected because selection is mandatory and must be visible.

## Decision 3: Introduce provider-generated content as first-class derived text

**Decision**: Add a generated-description/summary representation linked to the asset and extraction record, with provider route metadata, output kind, bounded text, status, timestamps, and safe failure state. Feed successful generated text into `SearchableChunkBuilder` and `searchable_chunks_fts`.

**Rationale**: Existing chunks and FTS already power lexical search, snippets, ranking, and asset matching. Treating generated descriptions/summaries as derived searchable chunks keeps search behavior consistent and avoids a parallel search path.

**Alternatives considered**:
- Store generated text only in `extraction_records.safe_summary`: rejected because summaries would not be reliably searchable or snippet-ranked.
- Store generated text only in provider-specific metadata tables: rejected because search would require extra joins and duplicate ranking logic.
- Reuse Office metadata only for all media: rejected because images/PDFs need provider route and output kind fields that are not Office-specific.

## Decision 4: Create prompt templates with explicit untrusted-data boundaries

**Decision**: Add separate prompt templates for image long descriptions, PDF short summaries, and Office short summaries. Each prompt uses clear system rules, inert untrusted file-derived data sections, output length limits, JSON response requirements, and no raw full-content reproduction.

**Rationale**: The feature creates prompts from user files. Prompt-injection resistance, privacy limits, and output bounding must be designed before implementation.

**Alternatives considered**:
- Reuse the current generic `metadataPayload`: rejected because it asks for concise labels/scene summaries and does not distinguish long image descriptions from short PDF/Office summaries.
- Put all content in a single user message without section boundaries: rejected because it weakens prompt-injection defenses.
- Ask for free-form natural language: rejected because structured output is easier to bound, sanitize, test, and store.

## Decision 5: Use Ollama `qwen3-embedding:4b` as the only embedding route

**Decision**: Replace heuristic embedding-provider/model selection with a fixed route to provider `ollama` and model `qwen3-embedding:4b`. Readiness for this model is checked separately from the selected Ollama generation model.

**Rationale**: The spec explicitly requires this embedding provider/model. Separating embedding readiness from generation model selection avoids conflicts where a user selects another Ollama generation model for descriptive enrichment.

**Alternatives considered**:
- Continue using the selected Ollama model if it looks like an embedding model: rejected because it violates the fixed model requirement.
- Embed with whichever local provider is automatic: rejected because it could choose oMLX or another provider.
- Degrade silently to lexical-only chunks when the fixed model is missing: rejected as the primary behavior because the spec requires readiness warning/failure for missing embedding model; lexical-only persistence may be allowed only as a clearly recorded partial state if implementation chooses partial indexing.

## Decision 6: Exclude audio/video from all provider-backed stages

**Decision**: For new audio/video indexing work, do not call provider chat, provider embeddings, or other AI-provider APIs. Persist only deterministic/local extractor output that does not prompt AI providers, or record a skipped provider stage when useful for diagnostics.

**Rationale**: The spec says never prompt AI providers to index video or audio files. Existing code currently embeds audio/video chunks through the generic embedding stage, so planning must explicitly remove that path for audio/video.

**Alternatives considered**:
- Keep embeddings for audio/video because embeddings are not summarization: rejected because embeddings still prompt an AI provider with audio/video-derived text.
- Disable audio/video indexing entirely: rejected because the user asked only to avoid AI providers, not to stop deterministic local metadata extraction.
- Keep existing historical audio/video chunks unchanged: accepted for existing data; new indexing must not create provider requests.

## Decision 7: Keep Office summaries on Hermes Agent route

**Decision**: Continue routing Office files only to Hermes Agent with selected Hermes profile, update prompt templates to request a short summary, and store the resulting summary through the same generated-content/chunk path used by image/PDF descriptions.

**Rationale**: The previous feature already introduced Hermes-only Office handling. This feature narrows output to short summaries and requires FTS searchability alongside image/PDF generated text.

**Alternatives considered**:
- Route Office through preferred provider: rejected by the spec.
- Keep Office-specific storage only: partially rejected because search and diagnostics benefit from a unified generated-content model.
- Require a selected model for Hermes Agent directly in LocalLens: rejected because Hermes Agent readiness is profile-based; its profile controls model/provider configuration.

## Decision 8: Use additive storage migrations and compatibility shims

**Decision**: Add migration-safe fields/tables for preferred provider selection, generated content, and fixed embedding metadata without deleting existing provider-setting fields during this feature. Treat legacy disabled provider values as visible providers during provider list normalization.

**Rationale**: Existing migrations and repositories already persist provider enablement and Office metadata. Additive migrations reduce data-loss risk and simplify upgrades from existing LocalLens databases.

**Alternatives considered**:
- Rewrite the base migration only: rejected because existing user databases need additive compatibility.
- Drop provider `is_enabled` from storage: rejected because it is a larger migration with broader compatibility risk.
- Store everything as opaque app setting strings: rejected because generated content and route metadata need searchable, queryable records.
