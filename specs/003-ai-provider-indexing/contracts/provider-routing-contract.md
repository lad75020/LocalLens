# Contract: Provider Routing

## Purpose

Define which provider may be contacted for each indexing stage and which readiness checks must pass before a request is made.

## Routing Matrix

| Media or Stage | Provider Route | Model/Profile Requirement | Provider Request Allowed | Failure or Skip Behavior |
|----------------|----------------|---------------------------|--------------------------|--------------------------|
| Image long description | User preferred provider | Hermes profile if Hermes; selected generation model if Ollama/oMLX; remote privacy/transport readiness if remote-capable | Yes, exactly one request per enrichment attempt | Safe retryable failure if preferred provider is not ready |
| PDF short summary | User preferred provider | Hermes profile if Hermes; selected generation model if Ollama/oMLX; remote privacy/transport readiness if remote-capable | Yes, exactly one request per enrichment attempt | Safe retryable failure if preferred provider is not ready |
| Office short summary | Hermes Agent | Valid selected Hermes profile | Yes, exactly one request per Office summarization attempt | Safe retryable failure if Hermes profile/provider is not ready |
| Embeddings for eligible non-audio/video chunks | Ollama | Fixed model `qwen3-embedding:4b` present and reachable | Yes, batched by bounded chunks | Partial indexing or safe retryable failure if model is unavailable |
| Audio files | None | None | No | Deterministic local indexing may continue; provider stage is skipped |
| Video files | None | None | No | Deterministic local indexing may continue; provider stage is skipped |

## Preferred Provider Selection Rules

1. Settings must persist exactly one preferred provider identifier for image/PDF enrichment.
2. Stage start captures the current preferred provider for that asset attempt.
3. If the user changes preference during indexing, already-running attempts continue with the captured provider or fail safely; new attempts use the new preference.
4. Failed attempts may be retried after the user changes provider, profile, model, credentials, or transport readiness.
5. No silent fallback to a different descriptive provider is allowed.

## Provider Readiness Rules

### Hermes Agent

- Requires transport readiness.
- Requires credentials when Hermes reports or configuration marks credentials as required.
- Requires selected profile ID to be present in the current available profiles list.
- Uses the selected profile for both preferred-provider image/PDF enrichment and Office summaries.

### Ollama

- Requires loopback transport readiness.
- Requires selected generation model before Ollama can be preferred for image/PDF enrichment.
- Requires model `qwen3-embedding:4b` before embedding attempts.
- The generation model and embedding model are separate readiness checks.

### oMLX

- Requires loopback transport readiness.
- Requires selected generation model before oMLX can be preferred for image/PDF enrichment.
- Never handles embeddings for this feature.

### Custom Remote

- Requires remote opt-in readiness, secure transport or approved development exception, credentials when configured, and explicit privacy copy before image/PDF content or derived text is transmitted.
- Never handles Office summaries or embeddings for this feature.

## Request Evidence Required in Tests

- Image route tests assert exactly one descriptive chat request to the preferred provider.
- PDF route tests assert exactly one summary chat request to the preferred provider.
- Office route tests assert Hermes Agent request with selected profile header or equivalent profile routing metadata.
- Embedding tests assert provider `ollama` and model `qwen3-embedding:4b` for every embedding request.
- Audio/video tests assert no chat or embedding request is made for those assets.
- URLProtocol helpers must read both `httpBody` and `httpBodyStream` when validating request bodies.
