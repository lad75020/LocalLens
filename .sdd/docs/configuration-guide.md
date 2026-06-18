# Configuration Guide

## Overview

LocalLens configuration is split between compile-time defaults in `BuildConfiguration`, persisted user settings in the local SQLite database, provider credentials in the Keychain, and macOS sandbox entitlements in the app target.

Configuration precedence for provider-backed work is:

1. Source code constants define default endpoints, limits, fixed provider identifiers, and setting keys.
2. Persisted local settings define selected providers, selected models, selected Hermes profiles, Office preferences, and provider state.
3. Runtime provider discovery updates available model/profile state and readiness warnings.
4. Provider routing uses readiness, transport, credentials, profile/model selection, and fixed route rules before any provider-backed stage runs.

## Environment Variables

No environment variable reads were identified in the evidence pass. The application is configured through local app storage, Keychain, build constants, and macOS entitlements rather than process environment variables.

## Build-Time Configuration

`LocalLens/Support/BuildConfiguration.swift` defines the main defaults:

| Constant | Value | Purpose |
|----------|-------|---------|
| `minimumMacOSVersion` | `26.0` | Target platform baseline |
| `omlxBaseURL` | `http://localhost:17998/v1` | Default oMLX OpenAI-compatible endpoint |
| `ollamaBaseURL` | `http://localhost:11434/v1` | Default Ollama OpenAI-compatible endpoint |
| `hermesAgentBaseURL` | `http://localhost:8642/v1` | Default Hermes Agent endpoint |
| `discoveryConcurrencyLimit` | `4` | Bounded discovery work |
| `providerConcurrencyLimit` | `2` | Bounded provider-backed work |
| `thumbnailMaxDimension` | `512` | Maximum generated thumbnail dimension |
| `videoMaxSampledFrames` | `12` | Maximum sampled frames for video analysis |
| `maxSearchResults` | `100` | Search result limit |
| `maxPromptCharacters` | `12000` | Provider prompt/input bound |
| `maxProviderQueryCharacters` | `512` | Provider query bound |
| `fixedEmbeddingProviderID` | `ollama` | Fixed embedding provider |
| `fixedEmbeddingModelID` | `qwen3-embedding:4b` | Fixed embedding model |
| `preferredAIProviderSettingKey` | `preferredAIProviderID` | App setting key for preferred descriptive provider |
| `providerTimeoutSeconds` | `30` | Provider request timeout bound |

## Project Configuration

`project.yml` defines the app and test targets.

| Setting | Value | Purpose |
|---------|-------|---------|
| `SWIFT_VERSION` | `6.0` | Swift language mode |
| `SWIFT_STRICT_CONCURRENCY` | `complete` | Strict concurrency checking |
| App deployment target | `macOS 26.0` | Minimum app runtime target |
| Bundle identifier | `com.laurent.locallens` | App bundle id |
| App category | `public.app-category.productivity` | macOS app metadata |
| Code signing style | `Manual` | Project signing configuration in this repo |

### Entitlements

| Entitlement | Value | Purpose |
|-------------|-------|---------|
| `com.apple.security.app-sandbox` | `true` | Run in the macOS app sandbox |
| `com.apple.security.files.user-selected.read-only` | `true` | Read user-selected files and folders |
| `com.apple.security.files.bookmarks.app-scope` | `true` | Persist app-scope security-scoped bookmarks |
| `com.apple.security.network.client` | `true` | Contact local/remote provider endpoints |

## Local Persistent Settings

LocalLens stores application settings in SQLite under the user's Application Support `LocalLens` directory.

| Storage area | Examples | Notes |
|--------------|----------|-------|
| `app_settings` | `preferredAIProviderID` | Generic app settings |
| `provider_settings` | Provider URL, transport state, credential state, selected model | Provider rows are visible and normalized enabled |
| `provider_model_selections` | Ollama/oMLX selected and available model ids | Required for provider-backed descriptive enrichment |
| `hermes_profile_selection` | Selected Hermes profile, available profiles, state | Required for Hermes-backed work and Office summaries |
| `office_preferences` | `.pptx`, `.docx`, `.xlsx` indexing toggles | Controls Office discovery and indexing eligibility |
| `generated_content_records` | Image descriptions, PDF summaries, Office summaries | Generated text with provider route metadata |

## Provider Configuration

### Provider Defaults

| Provider | Default URL | Default automatic indexing | Intended use |
|----------|-------------|----------------------------|--------------|
| oMLX | `http://localhost:17998/v1` | Yes | Local loopback descriptive generation when selected and ready |
| Ollama | `http://localhost:11434/v1` | Yes | Local loopback descriptive generation when selected and fixed embeddings |
| Hermes Agent | `http://localhost:8642/v1` | No | Hermes profile-backed inference and all Office summaries |
| Custom Remote | `https://example.invalid/v1` | No | Explicit remote-capable configuration target |

### Readiness Rules

| Provider or stage | Required readiness | Block behavior |
|-------------------|--------------------|----------------|
| Preferred image/PDF provider | Allowed transport, credentials when needed, and required profile/model state | Block the affected descriptive stage and record safe actionable failure |
| Hermes Agent | Allowed transport, credentials when needed, selected profile id, selected profile still available | Block Hermes-backed image/PDF or Office work until profile is valid |
| Ollama descriptive generation | Allowed loopback transport, selected generation model, selected model still available | Block Ollama descriptive generation until model is valid |
| oMLX descriptive generation | Allowed loopback transport, selected generation model, selected model still available | Block oMLX descriptive generation until model is valid |
| Embeddings | Ollama provider available, allowed loopback transport, model list contains `qwen3-embedding:4b` | Skip or partial-fail embedding stage safely, depending on caller path |
| Audio/video provider prompting | Never allowed | Return provider-skipped blocked route |

## Credentials

Provider credentials are handled by `ProviderCredentialStore` and must be stored in the macOS Keychain. Documentation and diagnostics must describe required credentials generically and must not include real secret values.

## Validation Rules

| Config | Rule | Error behavior |
|--------|------|----------------|
| Preferred AI provider | Must reference a visible provider before image/PDF provider enrichment | Stage is blocked with a safe message asking the user to select a preferred provider |
| Hermes profile | Must be selected and present in the discovered profile list before Hermes-backed work | Hermes-backed stage is blocked as unavailable or stale |
| Ollama/oMLX generation model | Must be selected and present in the available model list before descriptive generation | Provider-backed descriptive stage is blocked as unavailable or stale |
| Fixed embedding model | Ollama model list must include `qwen3-embedding:4b` | Embedding readiness is unavailable and affected embedding work is skipped or partial-failed safely |
| Transport | Provider transport must be allowed by `ProviderTransportPolicy` | Stage is blocked with transport-blocked category |
| Credentials | Required credentials must not be missing | Stage is blocked as unauthorized or credential required |
| Provider prompt length | Inputs are bounded by `maxPromptCharacters` and provider query limits | Content is truncated or bounded before provider calls |
| Source files | Source media and Office files must not be written, renamed, moved, deleted, or repaired | Tests and privacy audit enforce non-mutation; cleanup targets only local index data |

## Deployment Profiles

The repository does not define separate development, staging, or production profiles. The app is a local macOS application. Local provider availability depends on the user's machine and any local services they run.

### Development

- Use local Xcode builds.
- Use the shared `LocalLens` scheme.
- Use local app support storage unless UI tests pass `--ui-testing-fresh-state`.
- Run local provider services only when provider-backed manual QA is required.

### Distribution

- The repository evidence did not include a notarization, signing, or release automation script.
- Distribution builds should use the Xcode archive flow and an appropriate signing identity outside this repository's manual `CODE_SIGN_IDENTITY = -` development configuration.

## Security-Sensitive Configuration Notes

- Do not commit provider credentials.
- Do not put API keys in generated documentation, command examples, shell history, or process arguments.
- Treat Office document contents and generated provider output as untrusted data.
- Keep remote provider usage explicit and gated by transport/privacy readiness.
