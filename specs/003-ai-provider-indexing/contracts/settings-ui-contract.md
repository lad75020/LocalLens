# Contract: Settings UI

## Purpose

Define the visible Settings behavior for selecting a preferred AI provider, mandatory profile/model selections, readiness states, and removal of provider enable toggles.

## AI Providers Tab Requirements

### Provider Rows

- Every known provider row is visible as a configuration target.
- No provider row exposes a user-editable provider-level `Enabled` toggle.
- Each row shows provider name, endpoint or route label, locality, transport state, credential state, readiness state, and last safe error when present.
- Remote-capable rows show privacy and transport copy before data can be transmitted.

### Preferred Provider Control

- The tab provides a single preferred AI provider selection control for image/PDF enrichment.
- The control lists all visible provider rows.
- The selected provider is persisted immediately or through a clear Save action.
- Selecting a provider that is not ready is allowed as a preference, but affected indexing stages must remain blocked until readiness is fixed.
- The selected row clearly indicates it is used for image descriptions and PDF summaries only.

### Mandatory Hermes Profile Selection

- Hermes Agent row shows a profile picker.
- Empty profile selection is a not-ready state.
- Stale or unavailable selected profile is a not-ready state.
- A valid selected profile is required for Hermes-preferred image/PDF enrichment and all Office summaries.

### Mandatory Ollama Model Selection

- Ollama row shows a generation model picker.
- Empty or stale generation model selection is a not-ready state for Ollama-preferred image/PDF enrichment.
- Ollama row separately shows fixed embedding model readiness for `qwen3-embedding:4b`.
- The fixed embedding model cannot be edited from the generation model picker.

### Mandatory oMLX Model Selection

- oMLX row shows a generation model picker.
- Empty or stale generation model selection is a not-ready state for oMLX-preferred image/PDF enrichment.
- oMLX is never shown as an embedding provider for this feature.

### Office Section

- Office indexing copy states that Office summaries use Hermes Agent only.
- Office controls indicate that Hermes profile readiness is required.
- Office controls do not imply Ollama, oMLX, custom remote, or preferred provider routing.

## Settings Copy Guidelines

- Use utility copy: short labels, current status, next required action.
- Avoid marketing or vague assurance copy.
- Use safe terms: "Ready", "Select profile", "Choose model", "Transport blocked", "Remote provider requires privacy approval", "Embedding model missing".
- Do not show raw prompts, file contents, credentials, or full paths.

## Accessibility Requirements

- Preferred provider picker has a stable accessibility identifier.
- Hermes profile picker keeps its stable accessibility identifier.
- Ollama and oMLX model pickers keep stable accessibility identifiers.
- Fixed embedding readiness has a stable accessibility identifier.
- Provider readiness warnings are VoiceOver-readable.
- The tab remains keyboard-operable.

## Suggested Accessibility Identifiers

- `settingsPreferredAIProviderPicker`
- `settingsProviderReadiness_ollama`
- `settingsProviderReadiness_omlx`
- `settingsProviderReadiness_hermes-agent`
- `settingsFixedEmbeddingModelReadiness_ollama`
- `settingsRemoteProviderPrivacyWarning`

## UI Test Expectations

- Provider enable toggle identifiers are absent.
- Preferred provider picker persists selection across app restart.
- Hermes profile missing state blocks Hermes-backed stages.
- Ollama generation model missing state blocks Ollama preferred enrichment.
- oMLX generation model missing state blocks oMLX preferred enrichment.
- Ollama fixed embedding readiness is displayed separately from generation model selection.
