# Contract: Generated Content Storage and Search

## Purpose

Ensure generated image descriptions, PDF summaries, and Office summaries are persisted locally and searchable through the existing full-text search flow.

## Persisted Records

### Extraction Record

Each successful or partial provider-backed generated-text stage must create or update an extraction record with:

- `assetID`
- stage for generated image description, generated PDF summary, Office document summary, or embeddings
- `providerID` when a provider was contacted
- `providerMode`
- `status`
- bounded safe summary
- safe failure category when applicable
- timestamps

### Generated Content Record

Each generated description/summary must store:

- asset identifier
- extraction record identifier
- media type
- output kind
- provider identifier
- model identifier when available
- Hermes profile identifier when applicable
- bounded generated text
- prompt template name or version
- status and safe error category
- timestamps

### Searchable Chunk

Each generated text record must produce one or more searchable chunks with:

- asset identifier
- extraction record identifier
- generated-text chunk type
- bounded text
- normalized text
- optional embedding from fixed Ollama route
- embedding model `qwen3-embedding:4b` when embedding succeeds

## FTS Requirements

1. Generated image descriptions must be inserted into full-text search.
2. Generated PDF summaries must be inserted into full-text search.
3. Generated Office summaries must be inserted into full-text search.
4. FTS matching must return the original asset, folder context, match reason, and safe snippet.
5. FTS columns may be expanded or existing text columns may be mapped, but tests must prove terms found only in generated text return the asset.
6. Existing chunks must remain searchable after migration.

## Embedding Requirements

1. Eligible generated chunks may receive embeddings only from Ollama model `qwen3-embedding:4b`.
2. Audio/video-derived chunks must not be embedded during new indexing work.
3. If embedding fails after generated text is stored, the generated text remains searchable lexically and the asset is marked partial or the embedding stage records a safe retryable failure.
4. Embedding vectors must not be stored in logs or diagnostics.

## Retention and Rebuild

- Generated descriptions and summaries are derived local index data.
- Delete-index removes generated records, chunks, FTS entries, and embeddings without touching source files.
- Rebuild-index may regenerate generated text under the current provider preferences after user action.
- Changing preferred provider does not rewrite existing generated text until retry/reindex/rebuild is requested.

## Diagnostics Redaction

Diagnostics may include:

- provider ID
- model ID
- Hermes profile display name or ID when safe
- output kind
- status
- failure category
- retryability
- bounded counts and timestamps

Diagnostics must not include:

- raw prompts
- raw provider responses
- credentials or bearer tokens
- full source file paths
- full extracted document text
- full generated descriptions or summaries
- embedding vectors

## Acceptance Tests

- Store an image generated description with a unique token; FTS search for the token returns the image asset.
- Store a PDF generated summary with a unique token; FTS search for the token returns the PDF asset.
- Store an Office generated summary with a unique token; FTS search for the token returns the Office asset.
- Delete local index removes generated content and FTS entries while source fixture file size and modification date remain unchanged.
- Reindex regenerates generated content using the current provider preference for images/PDFs and Hermes Agent for Office.
