# User Guide

## Features

### Menu Bar Search

LocalLens runs from the macOS menu bar. You can search your indexed local media library without opening a normal Dock-style window.

**What it does**: Finds local screenshots, images, PDFs, Office documents, audio, and video by filename, extracted text, generated summaries, transcripts, labels, and semantic meaning.

**When to use it**: Use it when you remember what a file contains but not its filename or location.

### Watched Folders

You choose which folders LocalLens is allowed to read. The app stores app-scope bookmarks so it can continue indexing authorized folders across launches.

**What it does**: Adds, lists, enables, disables, removes, and reindexes folders.

**When to use it**: Use watched folders to define the private library boundary.

### Image and PDF Indexing

LocalLens indexes images and PDFs with thumbnails, extracted text, metadata, generated descriptions or summaries when configured, and searchable chunks.

**What it does**: Makes screenshots, photos, image-only PDFs, and text PDFs searchable by visible text, document text, descriptions, and summaries.

**When to use it**: Use it for screenshots, scanned documents, PDFs, research files, receipts, notes, and visual reference libraries.

### Office Document Indexing

LocalLens can index `.pptx`, `.docx`, and `.xlsx` files through Hermes Agent only. The matching Hermes document skill directive is included in the provider request for each document type.

**What it does**: Creates safe summaries and searchable text for selected Office document types.

**When to use it**: Use it when you want presentations, Word documents, and spreadsheets to appear in the same private search library as media files.

### Audio and Video Indexing

LocalLens can store local audio/video metadata, transcripts when local extraction succeeds, and bounded video scene metadata. New audio and video indexing work does not prompt AI providers.

**What it does**: Makes spoken words and bounded scene data searchable while keeping AI-provider prompting disabled for audio and video stages.

**When to use it**: Use it for local recordings, videos, screen captures, and clips that need transcript or scene search.

### AI Provider Preferences

Settings lets you choose exactly one preferred AI provider for image descriptions and PDF summaries. Hermes Agent, Ollama, oMLX, and custom remote providers remain visible as configuration targets, but readiness controls whether a stage can run.

**What it does**: Controls which provider may receive image/PDF descriptive enrichment requests.

**When to use it**: Use it when choosing between local models, Hermes Agent profiles, or explicitly configured remote-capable providers.

### Search Result Actions

Search results can be previewed, revealed in Finder, opened with the system default action, or copied as a path or snippet.

**What it does**: Lets you act on the original local file without leaving the search workflow.

**When to use it**: Use actions after you find the file you need.

### Privacy, Storage, and Diagnostics

LocalLens stores derived data locally and provides safe diagnostics and failure categories. Diagnostics avoid raw prompts, credentials, full paths, full provider responses, and full extracted/generated content by default.

**What it does**: Helps you understand indexing state, storage, failures, and provider readiness without exposing sensitive content.

**When to use it**: Use it when indexing fails, provider setup is missing, or you want to delete or rebuild local index data.

## Usage Instructions

### Add a Watched Folder

**Prerequisites**: LocalLens is running and you have a folder with supported files.

1. Open LocalLens from the menu bar.
2. Open Settings or the onboarding folder picker.
3. Choose Add Folder.
4. Select the folder you want LocalLens to index.
5. Confirm the folder appears in the watched folder list.
6. Wait for discovery and indexing to queue supported files.

**Expected result**: Supported files are discovered and indexing jobs are queued. Unsupported, hidden, package, and symlinked content is skipped safely.

### Search Your Library

**Prerequisites**: At least one watched folder has been indexed or partially indexed.

1. Open the LocalLens menu bar popover.
2. Type a natural-language query or exact text phrase.
3. Review ranked results, thumbnails, snippets, and match reasons.
4. Use keyboard navigation or pointer selection to choose a result.
5. Preview, reveal, open, copy path, or copy snippet as needed.

**Expected result**: Matching files appear with understandable match reasons such as filename, OCR text, PDF text, transcript, generated summary, or semantic match.

### Configure the Preferred AI Provider

**Prerequisites**: Open Settings and make sure the provider you want is reachable and ready.

1. Open Settings.
2. Go to the AI provider area.
3. Select one preferred provider for image descriptions and PDF summaries.
4. For Hermes Agent, select a valid Hermes profile.
5. For Ollama or oMLX, select a valid generation model.
6. For remote-capable providers, review privacy and transport copy before using them.
7. Confirm readiness warnings are cleared for the provider-backed stage you want to run.

**Expected result**: New image/PDF descriptive enrichment uses only the selected ready provider. LocalLens does not silently fall back to another provider.

### Configure Fixed Ollama Embeddings

**Prerequisites**: Ollama is available at the configured endpoint and exposes `qwen3-embedding:4b`.

1. Open Settings.
2. Check provider readiness for Ollama.
3. Make sure the fixed embedding model `qwen3-embedding:4b` is available.
4. Run indexing or reindexing on files with searchable chunks.

**Expected result**: Embedding requests use Ollama model `qwen3-embedding:4b` regardless of the preferred descriptive provider.

### Enable Office Indexing

**Prerequisites**: Hermes Agent is available, credentials are present when required, and a valid Hermes profile is selected.

1. Open Settings.
2. Enable the Office file types you want: `.pptx`, `.docx`, and/or `.xlsx`.
3. Select or refresh the Hermes Agent profile list.
4. Choose the profile to use for Hermes-backed inference.
5. Add or reindex a folder containing Office documents.

**Expected result**: Enabled Office files are queued and routed only to Hermes Agent. `.pptx`, `.docx`, and `.xlsx` requests use their matching Hermes document skill directive.

### Monitor, Pause, Resume, Cancel, and Retry Indexing

**Prerequisites**: Indexing work is queued or running.

1. Open the menu bar popover or Settings.
2. Review queue size, running state, completed count, failed count, and last indexed time.
3. Choose Pause to stop new work from starting.
4. Choose Resume to continue queued work.
5. Choose Cancel to stop in-progress work safely.
6. Retry failed work or reindex a file/folder when the underlying problem is fixed.

**Expected result**: Progress updates safely. Cancelled or partial work is not presented as a complete indexed record.

### Delete or Rebuild the Local Index

**Prerequisites**: You understand that this affects LocalLens-derived data, not your source files.

1. Open Settings.
2. Go to privacy or storage controls.
3. Choose delete local index or rebuild index.
4. Confirm the action.
5. Reindex watched folders if needed.

**Expected result**: LocalLens removes or regenerates its local derived index data. Source files are not deleted or modified.

## Configuration

| Option | Type | Default or source | Required | Description |
|--------|------|-------------------|----------|-------------|
| Watched folders | User-selected folders | Empty on first launch | Yes for indexing | Defines the private library boundary |
| Preferred AI provider | Provider id | Persisted in `app_settings` | Required for image/PDF provider enrichment | Single provider used for image descriptions and PDF summaries |
| Hermes profile | Profile id | User selection | Required for Hermes-backed work | Used by Hermes Agent for Office summaries and Hermes preferred-provider work |
| Ollama generation model | Model id | User selection | Required when Ollama is descriptive provider | Used for Ollama image/PDF descriptive enrichment |
| oMLX generation model | Model id | User selection | Required when oMLX is descriptive provider | Used for oMLX image/PDF descriptive enrichment |
| Ollama embedding model | Fixed model id | `qwen3-embedding:4b` | Required for embeddings | Used for all embedding requests |
| Office `.pptx` indexing | Boolean | User setting | No | Controls PowerPoint discovery/indexing eligibility |
| Office `.docx` indexing | Boolean | User setting | No | Controls Word discovery/indexing eligibility |
| Office `.xlsx` indexing | Boolean | User setting | No | Controls Excel discovery/indexing eligibility |

## Common Workflows

### Build a Private Screenshot and PDF Library

1. Add a folder containing screenshots, images, and PDFs.
2. Configure the preferred AI provider if you want generated image descriptions or PDF summaries.
3. Wait for indexing to complete or partially complete.
4. Search for visible text, PDF phrases, object descriptions, or generated summary terms.
5. Preview or reveal the matching file.

**Result**: You can find local visual and document files by content instead of filename.

### Add Office Files to the Search Library

1. Configure Hermes Agent credentials and profile selection.
2. Enable `.pptx`, `.docx`, and/or `.xlsx` indexing in Settings.
3. Add or reindex a folder containing Office files.
4. Wait for Hermes-backed summaries to complete.
5. Search for terms from the generated safe summaries or snippets.

**Result**: Office documents appear in the same search experience as media files while remaining on the Hermes Agent-only route.

### Recover from a Provider Readiness Problem

1. Open Settings.
2. Read the provider readiness warning.
3. If Hermes Agent is not ready, refresh profiles and select a valid profile.
4. If Ollama or oMLX is not ready, refresh models and select a valid model.
5. If the fixed embedding model is missing, install or expose `qwen3-embedding:4b` in Ollama.
6. Retry or reindex the affected files.

**Result**: Only the failed provider-backed stage is retried; LocalLens does not switch providers silently.

### Recover from Folder Access Problems

1. Open Settings.
2. Find the watched folder that needs attention.
3. Reauthorize the folder if access is stale or denied.
4. Retry failed jobs or reindex the folder.

**Result**: LocalLens regains read-only access and resumes indexing without modifying source files.

## Troubleshooting

### No search results appear

**Cause**: No folder is indexed, indexing is still running, the query has no matching chunks, or matching files are missing.

**Resolution**:
1. Add a watched folder.
2. Wait for indexing to complete or check progress.
3. Try a simpler query or an exact phrase from the file.
4. Reindex the folder if files were moved or changed.

### A provider-backed image or PDF stage is blocked

**Cause**: No preferred provider is selected, the provider is unreachable, transport is blocked, credentials are missing, or the selected model/profile is stale.

**Resolution**:
1. Open Settings.
2. Select one preferred provider.
3. Fix credentials or transport readiness.
4. Select a valid Hermes profile, Ollama model, or oMLX model as required.
5. Retry or reindex the affected asset.

### Office files do not index

**Cause**: Office indexing is disabled for that file type, Hermes Agent is unavailable, no Hermes profile is selected, or the document is unreadable.

**Resolution**:
1. Enable the needed Office file type in Settings.
2. Confirm Hermes Agent is reachable.
3. Select a valid Hermes profile.
4. Retry the Office indexing job.
5. If the file is password-protected or corrupt, resolve the file issue and reindex.

### Embeddings are unavailable

**Cause**: Ollama is unreachable or does not report the fixed model `qwen3-embedding:4b`.

**Resolution**:
1. Start or repair the Ollama endpoint.
2. Install or expose `qwen3-embedding:4b`.
3. Refresh provider readiness.
4. Reindex affected files if semantic search is required.

### Audio or video files are not sent to providers

**Cause**: This is expected behavior. LocalLens blocks AI-provider prompting for new audio and video indexing work.

**Resolution**:
1. Use local transcript or scene extraction paths where available.
2. Search by local transcript, metadata, filename, or scene chunks after indexing.

### Source files changed unexpectedly

**Cause**: LocalLens requirements and tests require source files to remain unchanged. A source change is expected to come from another app or user action, not LocalLens indexing.

**Resolution**:
1. Check Finder or file history for external edits.
2. Export redacted diagnostics if needed.
3. Reindex the folder to refresh derived LocalLens data.

### Diagnostics do not show raw prompts or full extracted text

**Cause**: This is expected. Diagnostics are intentionally redacted.

**Resolution**:
1. Use safe failure categories and readiness labels for troubleshooting.
2. Inspect source files manually only when you own the file and need detailed content validation.
