# Quickstart: AI Provider Indexing Preferences

## Prerequisites

- LocalLens project opened in Xcode as `LocalLens.xcodeproj`.
- XCodeMCP window tab available for LocalLens.
- Test fixtures for image, PDF, Office, audio, and video indexing.
- Mock or URLProtocol-backed provider clients for Ollama, oMLX, Hermes Agent, and custom remote.
- Ollama fixture response includes model `qwen3-embedding:4b` for embedding-readiness tests.

## Planning Verification Checklist

1. Review `spec.md` requirements FR-001 through FR-027.
2. Review provider routing contract and confirm no media route has ambiguous fallback.
3. Review generated-content storage contract and confirm generated text is searchable through FTS.
4. Review prompt safety contract before implementing prompt templates.
5. Review Settings UI contract before changing `SettingsWindow.swift`.

## Suggested Implementation Order

1. Add data-model and repository support for preferred provider selection and generated content records.
2. Add additive SQLite migrations and migration tests.
3. Update provider registry/settings normalization so provider rows are visible and provider enable toggles are no longer user-facing.
4. Add provider readiness service logic for preferred provider, mandatory Hermes profile, mandatory Ollama/oMLX generation model, and fixed Ollama embedding model.
5. Add safe prompt templates for image long description, PDF short summary, and Office short summary.
6. Add provider enrichment service with injected clients and strict one-provider routing.
7. Update `IndexCoordinator` image/PDF and Office paths to persist generated content and create searchable chunks.
8. Update embedding stage to use only Ollama `qwen3-embedding:4b` for eligible non-audio/video chunks.
9. Remove provider-backed embeddings or chat calls from audio/video indexing paths.
10. Update search, snippets, and ranking for generated description/summary chunk types.
11. Update diagnostics and privacy audit for provider route, readiness, skipped audio/video provider stages, and redaction.
12. Update Settings UI and UI tests.
13. Run targeted tests, full tests, then XCodeMCP build verification.

## Manual QA Scenarios

### Preferred provider selection

1. Open Settings.
2. Select Ollama as preferred provider.
3. Confirm the provider row shows selected generation model readiness.
4. Restart the app.
5. Confirm Ollama remains the preferred provider.

### Image description route

1. Configure a mock preferred provider.
2. Index an image fixture with a unique visual concept.
3. Assert exactly one chat request is sent to the preferred provider.
4. Search for a term that exists only in the generated description.
5. Confirm the image result appears with a safe snippet.

### PDF summary route

1. Configure a mock preferred provider.
2. Index a PDF fixture with a unique topic.
3. Assert exactly one chat request is sent to the preferred provider.
4. Search for a term that exists only in the generated summary.
5. Confirm the PDF result appears with a safe snippet.

### Office summary route

1. Select a valid Hermes Agent profile.
2. Index DOCX, PPTX, or XLSX fixture.
3. Assert request is routed only to Hermes Agent with the selected profile.
4. Search for a term that exists only in the Office summary.
5. Confirm the Office result appears with a safe snippet.

### Fixed embeddings

1. Configure Ollama model list with `qwen3-embedding:4b`.
2. Index eligible image/PDF/Office generated chunks.
3. Assert every embedding request targets provider `ollama` and model `qwen3-embedding:4b`.
4. Configure Ollama without that model.
5. Confirm embedding readiness warning or safe partial/failure is recorded.

### Audio/video exclusion

1. Index audio and video fixtures with provider request logging enabled.
2. Confirm no chat request is made.
3. Confirm no embedding request is made.
4. Confirm source file size and modification date are unchanged.
5. Confirm diagnostics show no raw file content.

### Remote privacy gate

1. Select a remote-capable provider as preferred.
2. Leave transport/privacy readiness incomplete.
3. Start image/PDF enrichment.
4. Confirm no request is sent and a safe readiness warning is shown.
5. Complete the explicit opt-in flow, then retry.

## Test Commands

Use XCodeMCP first for build/test discovery and verification. If XCodeMCP reports a generic failure, run targeted `xcodebuild` commands for actionable logs, then return to XCodeMCP for final build confirmation.

Suggested targeted test areas:

- `LocalLensTests/InferenceTests`
- `LocalLensTests/IndexingTests`
- `LocalLensTests/PrivacySecurityTests`
- `LocalLensTests/SearchTests`
- `LocalLensTests/StorageTests`
- `LocalLensUITests/SettingsProviderModelSelectionUITests.swift`
- `LocalLensUITests/SettingsHermesProfileSelectionUITests.swift`
- `LocalLensUITests/SettingsUITests.swift`

## Done Criteria

- Provider enable toggles are absent from Settings.
- Preferred provider is persisted and used for image/PDF enrichment only.
- Office summaries use Hermes Agent profile route only.
- Embeddings use Ollama `qwen3-embedding:4b` only.
- Audio/video indexing creates no AI-provider requests.
- Generated descriptions and summaries are stored locally and searchable by FTS.
- Diagnostics are redacted and recovery actions are actionable.
- Source files remain unchanged in tests.
- Relevant XCTest and UI test suites pass.
- XCodeMCP build succeeds.


## Verification Results (2026-06-16)

- XCodeMCP targeted regression rerun: `HermesProfileSelectionTests/testProviderRegistryMergesMissingHermesAgentDefaultWithoutOverwritingPersistedProviders`, `ProviderPrivacyDefaultsTests/testDefaultProvidersArePrivateAndRemoteGuarded`, and `ProviderTransportPolicyTests/testProviderRegistryDefaultsKeepHermesOutOfBulkIndexing` — **3 passed, 0 failed**.
- Targeted provider/generated-content suite via `xcodebuild test` fallback for detailed logs: `AIProviderRoutingPreferenceTests`, `GeneratedContentFTSSearchTests`, and two `ImagePDFIndexingPipelineTests` embedding regressions — **8 passed, 0 failed**.
- Full XCodeMCP test run: **99 total, 98 passed, 0 failed, 0 skipped, 1 not run** (`LocalLensUITestBase` is a base class/no-result entry).
- Diff safety scan: no fixture file modifications, no API key/secret/bearer-token/full local path hits in the code/spec diff.
- Final XCodeMCP build after documentation update: **succeeded** (0 errors).
