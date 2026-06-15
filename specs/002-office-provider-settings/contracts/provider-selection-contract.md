# Contract: Ollama and oMLX Model Selection

## Purpose

Defines how LocalLens discovers, displays, persists, validates, and uses selected models for local loopback providers Ollama and oMLX.

## Providers

| Provider ID | Display name | Default endpoint | Selection required for |
|---|---|---|---|
| `ollama` | Ollama | `http://localhost:11434/v1` | Ollama-backed inference/embeddings |
| `omlx` | oMLX | `http://localhost:17998/v1` | oMLX-backed inference/embeddings |

## Model Discovery

Request:

```http
GET {baseURL}/models
Authorization: Bearer ***
```

Expected OpenAI-compatible response:

```json
{
  "object": "list",
  "data": [
    {"id": "model-a"},
    {"id": "model-b"}
  ]
}
```

Rules:
- Run discovery asynchronously from Settings refresh.
- Apply provider timeout and transport policy.
- Preserve last selected model when discovery fails, but mark availability as unverified/unavailable.
- Do not block app launch, search, or Settings rendering while discovery is running.

## Selection State

```swift
struct ProviderModelSelectionState: Sendable, Equatable {
    var providerID: String
    var selectedModelID: String?
    var availableModelIDs: [String]
    var availabilityState: ProviderSelectionAvailability
    var lastRefreshedAt: Date?
    var lastSafeError: String?
}
```

Availability states:
- `unknown`: no refresh result yet.
- `available`: selected model is reported by provider.
- `stale`: selected model is no longer reported.
- `unavailable`: provider cannot be reached or reports no models.
- `unauthorized`: credentials rejected.
- `transportBlocked`: endpoint violates transport policy.

## Settings UI Contract

For each local provider row:
- Show provider health/status pills already present in Settings.
- Show a model picker when `availableModelIDs` is non-empty.
- Show selected model if it exists but is stale, with warning and required reselection before new provider-backed inference.
- Persist selection immediately when user chooses a model.
- Accessibility identifiers should distinguish provider and model picker, for example `settingsProviderModelPicker_ollama` and `settingsProviderModelPicker_omlx`.

## Inference Request Contract

All Ollama/oMLX inference calls must use the selected model:

```http
POST {baseURL}/embeddings
Content-Type: application/json
Authorization: Bearer ***

{
  "model": "{selectedModelID}",
  "input": ["bounded chunk"],
  "encoding_format": "float"
}
```

Chat/metadata requests follow the same model rule:

```json
{
  "model": "{selectedModelID}",
  "messages": [ ... ],
  "temperature": 0
}
```

Rules:
- Do not silently fall back to `availableModelIDs[0]` after a user selection exists.
- If no model is selected, provider-backed inference for that provider is not ready.
- If the selected model is stale, block new provider-backed automatic indexing and show a Settings warning.

## Acceptance Tests

- Discovery parses model IDs from Ollama-compatible `/models` response.
- Discovery parses model IDs from oMLX-compatible `/models` response.
- Selecting a model persists across app restart.
- Embedding request uses selected Ollama model.
- Embedding request uses selected oMLX model.
- Stale selected model is shown as stale and blocks new provider-backed work.
- Provider refresh failure preserves previous selected model and records redacted safe error.
