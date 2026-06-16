# Data Model: AI Provider Indexing Preferences

## Entity: PreferredAIProviderSelection

**Purpose**: Captures the user's single provider choice for image long descriptions and PDF short summaries.

**Fields**:
- `providerID`: stable provider identifier such as `ollama`, `omlx`, `hermes-agent`, or `custom`.
- `selectedAt`: timestamp of the last user selection.
- `lastValidatedAt`: timestamp of the last readiness validation.
- `availabilityState`: `unknown`, `available`, `stale`, `unavailable`, `unauthorized`, or `transportBlocked`.
- `lastSafeError`: optional redacted message explaining why the provider is not ready.

**Validation rules**:
- Exactly one preferred provider may be selected for image/PDF enrichment.
- The provider must exist in provider settings before enrichment starts.
- If the provider is remote-capable, transport/privacy/credential readiness must pass before content leaves the Mac.
- If the provider is Hermes Agent, a valid Hermes profile is required.
- If the provider is Ollama or oMLX, a valid selected generation model is required.

**Relationships**:
- References `ProviderSetting.providerID`.
- Uses `ProviderReadinessState` to decide whether enrichment can start.

## Entity: ProviderReadinessState

**Purpose**: Replaces user-facing provider enablement with actionable readiness.

**Fields**:
- `providerID`: provider identifier.
- `isVisibleConfigurationTarget`: always true for known provider rows.
- `transportState`: existing transport policy state.
- `credentialState`: existing credential readiness state.
- `generationModelState`: selected model state for Ollama and oMLX.
- `hermesProfileState`: selected profile state for Hermes Agent.
- `preferredProviderState`: whether this provider is the current preferred descriptive provider.
- `embeddingModelState`: fixed Ollama embedding model readiness, populated for Ollama.
- `lastSafeError`: optional redacted readiness message.

**Validation rules**:
- Provider-level enable toggles are not user-editable.
- Providers may be visible but not ready.
- Readiness must be evaluated per requested stage because Hermes, Ollama, oMLX, custom, and embedding routes have different requirements.

## Entity: ProviderModelSelection

**Purpose**: Existing selected generation model for Ollama and oMLX.

**Fields**:
- `providerID`
- `selectedModelID`
- `availableModelIDs`
- `availabilityState`
- `lastRefreshedAt`
- `lastSafeError`

**Validation rules**:
- Ollama generation model selection is mandatory before Ollama can be preferred for image/PDF enrichment.
- oMLX generation model selection is mandatory before oMLX can be preferred for image/PDF enrichment.
- The fixed embedding model `qwen3-embedding:4b` does not replace or satisfy the selected Ollama generation model requirement.

## Entity: HermesProfileSelection

**Purpose**: Existing selected Hermes Agent profile used by Hermes-backed enrichment.

**Fields**:
- `selectedProfileID`
- `selectedProfileDisplayName`
- `availableProfiles`
- `availabilityState`
- `lastRefreshedAt`
- `lastSafeError`

**Validation rules**:
- A valid selected profile is mandatory before Hermes Agent can be preferred for image/PDF enrichment.
- A valid selected profile is mandatory before Office summarization starts.
- Missing or stale profile selection blocks only the affected Hermes-backed stage.

## Entity: EmbeddingRoute

**Purpose**: Fixed embedding configuration for all eligible searchable chunks.

**Fields**:
- `providerID`: always `ollama`.
- `modelID`: always `qwen3-embedding:4b`.
- `availabilityState`: readiness of this exact model.
- `lastValidatedAt`: timestamp of the last model-list or request validation.
- `lastSafeError`: optional redacted failure.

**Validation rules**:
- No provider other than Ollama may be used for embeddings.
- No model other than `qwen3-embedding:4b` may be used for embeddings.
- Audio/video chunks are not sent to the embedding route for new indexing work.
- Image, PDF, Office, filename, visible-text, generated-summary, and generated-description chunks may use this route if ready and eligible.

## Entity: GeneratedContentRecord

**Purpose**: Stores provider-generated image descriptions, PDF summaries, and Office summaries.

**Fields**:
- `id`: record identifier.
- `assetID`: indexed media asset identifier.
- `extractionRecordID`: related extraction record identifier.
- `mediaType`: `image`, `pdf`, or `office`.
- `outputKind`: `imageLongDescription`, `pdfShortSummary`, or `officeShortSummary`.
- `providerID`: provider that generated the text.
- `providerMode`: local loopback or remote opt-in route used.
- `modelID`: generation model when available.
- `hermesProfileID`: selected Hermes profile when Hermes Agent is used.
- `boundedText`: sanitized generated text used for storage and search.
- `sourcePromptVersion`: prompt template version or stable name.
- `status`: `complete`, `partial`, `failed`, or `cancelled`.
- `errorCategory`: optional safe failure category.
- `createdAt`
- `updatedAt`

**Validation rules**:
- `boundedText` must be capped before storage.
- Raw prompts, full source file text, credentials, and full provider responses must not be stored in this record.
- Image records must use the preferred provider selected at stage start.
- PDF records must use the preferred provider selected at stage start.
- Office records must use Hermes Agent regardless of preferred provider.
- Audio/video records are not created by provider prompts for new indexing work.

**Relationships**:
- Belongs to `MediaAsset`.
- Links to `ExtractionRecord`.
- Produces one or more `SearchableGeneratedChunk` rows.

## Entity: SearchableGeneratedChunk

**Purpose**: Makes generated descriptions/summaries searchable through existing full-text and ranking paths.

**Fields**:
- `id`: chunk identifier.
- `assetID`: indexed asset identifier.
- `extractionRecordID`: generated content extraction record identifier.
- `chunkType`: `imageDescription`, `pdfSummary`, or `officeSummary` after enum expansion, or mapped compatible existing chunk types if implementation avoids enum expansion.
- `text`: bounded chunk text.
- `normalizedText`: normalized text for lexical matching.
- `embedding`: optional vector generated by fixed Ollama route.
- `embeddingModel`: `qwen3-embedding:4b` when embedding succeeds.
- `confidence`: optional provider confidence if available.
- `createdAt`

**Validation rules**:
- Generated text chunks must be inserted into FTS in the correct searchable columns.
- Search result snippets must use redacted/bounded chunk text.
- Existing generated chunks are not silently rewritten when provider preference changes.

## Entity: ProviderRoutingFailure

**Purpose**: Records safe failure or skip outcomes for provider-backed stages.

**Fields**:
- `id`
- `assetID`
- `watchedFolderID`
- `stage`: e.g. `imageDescription`, `pdfSummary`, `officeSummary`, `embeddings`, or `audioVideoProviderSkipped`.
- `category`: safe failure category.
- `retryability`: retry, reauthorize, ignore, rebuildIndex, or notRetryable.
- `safeMessage`: redacted user-visible message.
- `providerID`: attempted provider when applicable.
- `modelID`: attempted model when applicable.
- `createdAt`
- `resolvedAt`

**Validation rules**:
- No raw prompts, raw responses, full paths, credentials, or full extracted text are stored.
- Missing readiness is retryable after the user selects a provider/profile/model or reauthorizes transport.
- Audio/video provider skips may be diagnostic-only and should not imply source indexing failure.

## State Transitions

### Preferred provider readiness

```text
unknown -> available -> stale -> available
unknown -> unavailable -> available
unknown -> transportBlocked -> available
unknown -> unauthorized -> available
```

### Generated content enrichment

```text
queued -> indexing -> complete
queued -> indexing -> partial
queued -> indexing -> failed
queued -> indexing -> cancelled
failed -> queued -> indexing
partial -> queued -> indexing
```

### Fixed embedding route

```text
notValidated -> available
notValidated -> unavailable
available -> stale
stale -> available
unavailable -> available
```

## Migration Notes

- Additive migrations should add generated-content persistence and FTS compatibility without deleting existing Office metadata.
- Existing provider settings with `is_enabled = 0` should still appear as visible provider rows after this feature; user-facing routing uses readiness instead of the old enable value.
- Existing chunks remain searchable; rebuild/reindex flows can regenerate generated content under current preferences only when the user triggers them.
