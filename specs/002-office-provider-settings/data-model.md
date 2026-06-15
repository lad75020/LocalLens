# Data Model: Office Indexing and Provider Settings

## Overview

This feature extends the existing local LocalLens database with Office indexing preferences, selected provider models, Hermes Agent profile selection, and Office extraction/indexing records. Source files remain read-only; all new state is derived local state that can be deleted or rebuilt.

## Entity: OfficeIndexingPreference

Represents the user-controlled file-type toggles for Hermes Agent Office indexing.

| Field | Type | Notes |
|---|---|---|
| pptxEnabled | Bool | Whether `.pptx` files are eligible for Hermes Agent indexing |
| docxEnabled | Bool | Whether `.docx` files are eligible for Hermes Agent indexing |
| xlsxEnabled | Bool | Whether `.xlsx` files are eligible for Hermes Agent indexing |
| requiresHermesAgent | Bool | Always true for this feature |
| updatedAt | Date | Last user or migration update |

Validation:
- Each toggle is independent.
- If Hermes Agent is disabled/unavailable or has no valid profile selection, Office files must not start indexing even when toggles are enabled.
- Preferences default to disabled for all three types.

Relationships:
- Controls `MediaDiscoveryService` eligibility for Office files.
- Controls `OfficeDocumentExtractor` job creation.

## Entity: ProviderModelSelection

Represents the selected model for a local provider.

| Field | Type | Notes |
|---|---|---|
| providerID | String | `ollama` or `omlx` |
| selectedModelID | String? | User-selected model used for inference |
| availableModelIDs | [String] | Last discovered provider models |
| availabilityState | enum | unknown, available, unavailable, stale, unauthorized, transportBlocked |
| lastRefreshedAt | Date? | Last completed model refresh |
| lastSafeError | String? | Redacted user-safe refresh error |
| updatedAt | Date | Last persisted selection update |

Validation:
- `providerID` must be one of the local loopback providers for this feature.
- `selectedModelID` must either be in `availableModelIDs` or be marked stale/unverified.
- Inference calls for Ollama/oMLX must use `selectedModelID`; no first-model fallback is allowed once the user has selected a model.
- Missing selected model blocks provider-backed indexing/inference for that provider and shows a Settings readiness warning.

Relationships:
- Extends or complements existing `ProviderSetting`.
- Used by embedding/chat/inference request builders.

## Entity: HermesProfileSelection

Represents the selected Hermes Agent profile for Hermes-backed inference.

| Field | Type | Notes |
|---|---|---|
| providerID | String | Always `hermes-agent` |
| selectedProfileID | String? | Stable API/profile identifier used on requests |
| selectedProfileDisplayName | String? | User-facing name, if reported |
| availableProfiles | [HermesProfileSummary] | Last discovered provider-reported profiles |
| availabilityState | enum | unknown, available, unavailable, stale, unauthorized, transportBlocked |
| lastRefreshedAt | Date? | Last completed profile refresh |
| lastSafeError | String? | Redacted user-safe refresh error |
| updatedAt | Date | Last selection update |

Validation:
- `selectedProfileID` must match a reported profile before Hermes-backed Office indexing starts.
- If the list contains a visible default profile and no selection exists, LocalLens may initialize the selection to that displayed default and show it to the user.
- Stale profile selections block new Hermes-backed Office jobs until the user refreshes or selects a valid profile.

Relationships:
- Used by Hermes Agent requests through request metadata/header control.
- Displayed in Settings AI Providers tab.

## Value Object: HermesProfileSummary

Represents one provider-reported Hermes profile.

| Field | Type | Notes |
|---|---|---|
| id | String | Stable profile id from provider API |
| displayName | String | Human-readable name |
| isDefault | Bool | Whether API reports it as default/current |
| modelDisplayName | String? | Optional model/provider summary shown in Settings |
| supportsReasoning | Bool? | Optional capability metadata if API reports it |
| updatedAt | Date? | Optional provider-side timestamp |

Validation:
- `id` is required and must not be empty.
- UI must display `displayName` when present, otherwise `id`.

## Entity: OfficeIndexJob

Represents queued work for one Office document.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local job id |
| assetID | UUID | Parent `MediaAsset` |
| officeKind | enum | pptx, docx, xlsx |
| providerID | String | Always `hermes-agent` |
| hermesProfileID | String | Selected profile captured at job start |
| requiredSkillDirective | String | Literal directive for prompt construction |
| status | IndexState | queued, indexing, partial, complete, failed, cancelled |
| attemptCount | Int | Retry count |
| progressCompleted | Int | Stage progress |
| progressTotal | Int? | Stage total |
| lastErrorCategory | FailureCategory? | Safe category |
| createdAt | Date | Job creation |
| startedAt | Date? | Job start |
| completedAt | Date? | Job completion |

Validation:
- `providerID` must be `hermes-agent`.
- `requiredSkillDirective` must exactly match the Office kind:
  - pptx → `Use the /pptx skill`
  - docx → `Use the /docx skill`
  - xlsx → `Use the /xlsx skill`
- If Office indexing is disabled after queueing but before start, queued jobs are cancelled or marked ignored according to Settings action copy.

Relationships:
- Can be represented by existing `IndexJob` with Office-specific fields in companion metadata, or by extending `IndexJob` if migration is acceptable.
- Produces `OfficeExtractionRecord` and `SearchableChunk` rows.

## Entity: OfficeExtractionRecord

Represents Hermes Agent-derived Office indexing output.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identifier |
| assetID | UUID | Parent asset |
| officeKind | enum | pptx, docx, xlsx |
| stage | enum | officeMetadata, officeText, officeSummary, embeddings |
| providerID | String | `hermes-agent` |
| hermesProfileID | String | Profile used |
| status | IndexState | partial/complete/failed/cancelled |
| outputSummary | String? | Safe bounded summary for UI |
| safeSnippet | String? | Optional bounded searchable snippet |
| errorCategory | FailureCategory? | Safe failure category |
| createdAt | Date | Audit timestamp |
| updatedAt | Date | Audit timestamp |

Validation:
- Raw prompts and raw provider responses are not stored by default.
- Summaries/snippets are bounded and redacted for diagnostics.
- Full extracted text, if stored for search, goes through `SearchableChunk` with local retention controls.

Relationships:
- Parent `MediaAsset` has many Office extraction records.
- Search results can cite Office record snippets and match reasons.

## Entity Updates

### MediaType / Office Kind

Add enough type information to identify Office results separately from image/pdf/audio/video. Preferred:

| Type | Values |
|---|---|
| MediaType | image, pdf, audio, video, presentation, document, spreadsheet |
| OfficeDocumentKind | pptx, docx, xlsx |

Rules:
- Office media types are eligible only when corresponding `OfficeIndexingPreference` toggle is enabled.
- Search filters and result labels should show the Office kind.

### ProviderSetting

Extend or companion with:

| Field | Type | Notes |
|---|---|---|
| selectedModelID | String? | Used for Ollama/oMLX inference |
| supportsModelSelection | Bool | True for Ollama/oMLX |
| supportsProfileSelection | Bool | True for Hermes Agent |
| supportsOfficeIndexing | Bool | True only for Hermes Agent |

Rules:
- Existing provider enabled/automatic settings are preserved during migration.
- Remote/custom provider rows remain excluded from Office indexing.

### SearchableChunk

Office chunks use existing fields:

| Field | Office usage |
|---|---|
| chunkType | visibleText or semantic until a dedicated Office match reason is added |
| text | Bounded Office text/summary/snippet |
| embeddingModel | Selected model/profile-aware model identifier when embeddings exist |
| pageNumber/timestamp | Optional; page/slide/sheet context may be encoded in snippet until dedicated fields are added |

Future extension:
- Add `MatchReason` values such as `officeText`, `slideText`, `worksheetText` if search UI needs finer labels.

## State Transitions

### Provider Model Selection

```text
unknown → refreshing → available
unknown → refreshing → unavailable
available → stale (selected model no longer reported)
stale → available (user selects reported model)
unavailable → refreshing → available
```

### Hermes Profile Selection

```text
unknown → refreshing → available
available → stale (selected profile no longer reported)
stale → available (user selects valid profile)
any → transportBlocked / unauthorized / unavailable
```

### Office Index Job

```text
queued → indexing → complete
queued → indexing → partial
queued → indexing → failed
queued → cancelled
indexing → cancelled
failed → queued (retry)
partial → queued (reindex)
```

## Retention and Deletion

- Office preferences and selected provider/profile settings persist across app restarts.
- Office extraction records, chunks, embeddings, failures, and jobs are deleted by existing local index deletion/rebuild flows.
- Source Office files are never modified by any state transition.
