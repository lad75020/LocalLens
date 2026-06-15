# Contract: Hermes Agent Profile Selection

## Purpose

Defines how LocalLens discovers Hermes Agent profiles, lets the user choose one in Settings, and uses that selected profile for Hermes-backed inference, especially Office document indexing.

## Profile Discovery

Preferred request:

```http
GET {hermesBaseURL}/profiles
Authorization: Bearer ***
```

Expected response shape:

```json
{
  "data": [
    {
      "id": "default",
      "name": "Default",
      "is_default": true,
      "model": "hermes-agent",
      "provider": "openrouter"
    },
    {
      "id": "office",
      "name": "Office",
      "is_default": false,
      "model": "hermes-agent"
    }
  ]
}
```

Compatibility:
- Accept alternate field names commonly used by profile APIs: `display_name`, `displayTitle`, `friendly_name`, or `name`.
- If only a default profile is returned, show it explicitly as selectable rather than hiding the choice.
- If the endpoint is missing/unavailable, mark Hermes profile selection unavailable and block new Hermes-backed Office indexing until resolved.

## Selection State

```swift
struct HermesProfileSelectionState: Sendable, Equatable {
    var selectedProfileID: String?
    var selectedProfileDisplayName: String?
    var availableProfiles: [HermesProfileSummary]
    var availabilityState: ProviderSelectionAvailability
    var lastRefreshedAt: Date?
    var lastSafeError: String?
}
```

Rules:
- Persist selected profile across app restarts.
- A selected profile must match a provider-reported profile before new Hermes-backed Office jobs start.
- If the selected profile disappears, mark state as stale and require user action.
- If no profile is selected and the API reports exactly one default/current profile, LocalLens may initialize selection to that visible default.

## Settings UI Contract

The Hermes Agent provider row shows:
- Provider readiness status.
- Profile picker populated from provider-reported profiles.
- Selected profile display name and safe metadata summary when available.
- Warning text if selected profile is stale/unavailable.
- Accessibility identifier such as `settingsHermesProfilePicker`.

Copy requirements:
- Explain that Hermes profiles can use different models/providers/skills.
- Explain that Office indexing uses the selected profile.
- Do not expose secrets, full config file paths, or raw provider errors in ordinary Settings copy.

## Request Contract

Hermes Agent OpenAI-compatible requests keep `model` as the advertised compatibility model id and send profile separately.

Example:

```http
POST {hermesBaseURL}/chat/completions
Content-Type: application/json
Authorization: Bearer ***
X-Hermes-Profile: {selectedProfileID}

{
  "model": "hermes-agent",
  "messages": [ ... ],
  "temperature": 0
}
```

Rules:
- Do not put profile id into `model` unless the provider API explicitly documents profile ids as model ids for this endpoint.
- If LocalLens centralizes Hermes request metadata differently, that centralized mechanism must be documented and tested as equivalent to selecting the profile.
- Profile id is recorded in derived local extraction records for traceability, not in diagnostics with sensitive config details.

## Office Indexing Readiness

Hermes Agent is ready for Office indexing when all are true:
- Provider is enabled.
- Transport policy allows the endpoint.
- Provider health is healthy or not known to be blocked.
- A selected profile exists and is not stale.
- The matching Office file-type toggle is enabled.

If any condition fails, Office files do not start Hermes indexing and Settings shows the missing requirement.

## Acceptance Tests

- Profile discovery parses `id`, display name, and default flag.
- User-selected profile persists across app restart.
- Hermes Office request includes selected profile control and keeps `model` as Hermes compatibility model.
- Stale selected profile blocks new Office indexing.
- Missing profile endpoint results in safe unavailable state with redacted error.
- Profile picker remains keyboard and VoiceOver accessible.
