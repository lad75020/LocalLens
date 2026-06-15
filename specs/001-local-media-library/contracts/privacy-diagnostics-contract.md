# Contract: Privacy, Diagnostics, and Settings

## Privacy Defaults

- Local AI and Apple framework extractors are the default.
- oMLX and Ollama loopback providers may be enabled for local inference after health checks.
- Hermes Agent is listed as a local loopback provider but disabled for automatic bulk indexing by default.
- Custom remote providers are disabled by default.
- No file bytes, extracted text, transcripts, filenames, prompts, embeddings, or metadata are sent to non-loopback providers without explicit opt-in.

## Settings Surfaces

Settings sections:
1. Watched Folders
2. Indexing
3. AI Providers
4. Privacy & Storage
5. Diagnostics
6. Shortcuts

## Storage Controls

Users can:
- View local index/cache size.
- Delete index data.
- Rebuild index from source files.
- Remove a watched folder from the index.
- Export redacted diagnostics.

Deleting index/cache data never deletes source media.

## Diagnostic Export Shape

```json
{
  "appVersion": "LocalLens 0.x",
  "schemaVersion": 1,
  "createdAt": "2026-06-15T00:00:00Z",
  "counts": {
    "watchedFolders": 2,
    "assets": 10000,
    "failures": 4
  },
  "providerHealth": [
    {"id": "omlx", "locality": "localLoopback", "status": "unavailable"}
  ],
  "failureCategories": [
    {"category": "permissionDenied", "count": 1},
    {"category": "modelUnavailable", "count": 3}
  ],
  "redaction": {
    "fullPaths": "hashed",
    "transcripts": "omitted",
    "extractedText": "omitted",
    "credentials": "omitted",
    "rawProviderBodies": "omitted"
  }
}
```

## Redaction Rules

Never include by default:
- Credentials or API keys.
- Raw provider request/response bodies.
- Full extracted OCR/PDF text.
- Full transcripts.
- Full prompts.
- Full file paths in exported diagnostics.
- File bytes or thumbnails in diagnostics.

Allowed by default:
- Counts.
- Safe categories.
- App version/schema version.
- Provider id/locality/status.
- Hashed/truncated path identifiers.
- User-approved short safe messages.

## Remote Provider Warning Copy

When enabling a non-loopback provider, the UI must say, in product language:

"Remote AI can receive selected file content or derived text when indexing. Keep this off unless you trust the endpoint. LocalLens never enables remote AI automatically."

User must confirm before automatic indexing can use the provider.
