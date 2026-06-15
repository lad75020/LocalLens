# Feature Specification: LocalLens Private Media Library MVP

**Feature Branch**: `001-local-media-library`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "Use all MVP requirements found in file LocalLens/plan/feature-local-media-library-mvp-1.md to specify LocalLens project: a private macOS media library menu bar application that indexes screenshots, images, PDFs, audio, and videos with local AI so users can search by meaning, text, objects, transcript, or scene."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add Private Media Library Folders (Priority: P1)

A user adds one or more local folders that contain screenshots, images, PDFs, audio files, and videos so LocalLens can build a private searchable library from user-selected content.

**Why this priority**: Without explicit folder onboarding and persistent access, the product cannot discover or index any user media.

**Independent Test**: Starting from a fresh install, a user can add a folder, see it listed in Settings, quit and relaunch the app, and see that the folder remains available for indexing without reselecting it.

**Acceptance Scenarios**:

1. **Given** a fresh install with no folders, **When** the user opens the menu bar app and chooses to add a folder, **Then** the selected folder appears in the watched folder list and indexing is queued.
2. **Given** a watched folder was added in a previous app session, **When** the user relaunches the app, **Then** the folder remains authorized or is clearly marked as needing reauthorization.
3. **Given** a watched folder is removed by the user, **When** the removal is confirmed, **Then** LocalLens stops indexing that folder and no longer shows new results from that folder.
4. **Given** a user selects a folder with unsupported files mixed with supported media, **When** discovery runs, **Then** only supported media types are queued and unsupported files are ignored without user-facing noise.

---

### User Story 2 - Index Screenshots, Images, and PDFs (Priority: P1)

A user lets LocalLens process screenshots, images, and PDFs so visible text, document text, basic visual concepts, thumbnails, and searchable metadata become available locally.

**Why this priority**: Image and PDF search is the smallest compelling alpha and delivers immediate private-search value.

**Independent Test**: With a fixture folder containing screenshots and PDFs, the user can wait for indexing to finish and then search for visible screenshot text, PDF text, and a visual concept to retrieve matching files.

**Acceptance Scenarios**:

1. **Given** a watched folder contains screenshots or images with readable text, **When** indexing completes, **Then** searching for that text returns the matching image or screenshot.
2. **Given** a watched folder contains PDFs with selectable text, **When** indexing completes, **Then** searching for a phrase from the PDF returns the matching PDF with a text-based match reason.
3. **Given** a watched folder contains image-only PDF pages where local recognition is feasible, **When** indexing processes those pages within MVP bounds, **Then** recognized text becomes searchable or the file is reported as partially indexed.
4. **Given** indexed images and PDFs have thumbnails, **When** results are displayed, **Then** each result shows a bounded preview thumbnail where available.

---

### User Story 3 - Search by Meaning, Text, Objects, Transcript, or Scene (Priority: P1)

A user enters natural-language queries in the menu bar popover and receives ranked results across filenames, extracted text, document text, transcripts, visual labels, and semantic metadata.

**Why this priority**: The main product promise is finding local media by what it contains rather than by filename or folder location.

**Independent Test**: After indexing a mixed fixture library, a user can search for exact text, a concept such as "terminal error screen", and a phrase from a transcript, then inspect ranked results with clear match explanations.

**Acceptance Scenarios**:

1. **Given** a library has indexed filenames, extracted text, transcripts, visual labels, and semantic metadata, **When** the user searches from the menu bar popover, **Then** matching assets are ranked and displayed in a single result list.
2. **Given** a result matches for multiple reasons, **When** it appears in search results, **Then** the user sees the strongest visible match reason such as filename, OCR text, PDF text, transcript, visual label, or semantic match.
3. **Given** a query has no matching assets, **When** the search finishes, **Then** the user sees an empty state that suggests adding folders, waiting for indexing, or trying a different query.
4. **Given** an indexed file has been deleted or moved, **When** it would otherwise appear in results, **Then** LocalLens marks it as missing or excludes it without crashing.

---

### User Story 4 - Index Audio and Video Privately (Priority: P2)

A user includes audio and video files in watched folders so spoken words, basic media metadata, sampled video scenes, and thumbnails become searchable without cloud processing by default.

**Why this priority**: Audio and video support completes the full media-library promise after the image/PDF search path is usable.

**Independent Test**: With short fixture audio and video files, the user can index the folder, search for spoken transcript text, and search for a sampled video scene or visible text from a sampled frame.

**Acceptance Scenarios**:

1. **Given** a watched folder contains supported audio files, **When** indexing completes, **Then** the files have duration metadata and transcript-based search entries where local transcription succeeds.
2. **Given** a watched folder contains supported videos, **When** indexing completes, **Then** the files have duration metadata, representative thumbnails or keyframes, and scene metadata from bounded sampled frames.
3. **Given** a supported video contains an audio track, **When** transcription succeeds, **Then** spoken content from the video is searchable with a timestamp hint where available.
4. **Given** an audio or video file is too large, corrupted, unsupported, or cannot be transcribed, **When** indexing reaches that file, **Then** the failure is recorded safely and the rest of the library continues indexing.

---

### User Story 5 - Preview, Reveal, and Reuse Results (Priority: P2)

A user selects a search result and quickly previews it, reveals it in Finder, opens it, or copies useful result information without leaving the LocalLens workflow.

**Why this priority**: Search is only useful if the user can act on the file immediately and confidently.

**Independent Test**: From a search result list, the user can keyboard-select a result, preview it, reveal it in Finder, open it, and copy its path or extracted snippet.

**Acceptance Scenarios**:

1. **Given** search results are visible, **When** the user selects a result and triggers preview, **Then** the original file opens in a platform preview without modifying the file.
2. **Given** search results are visible, **When** the user chooses reveal, **Then** Finder opens with the original file selected.
3. **Given** a result contains a text, transcript, or document snippet, **When** the user chooses copy snippet, **Then** the snippet is copied without exposing unrelated extracted content.
4. **Given** the user navigates by keyboard, **When** they move through results and actions, **Then** search, selection, preview, reveal, and settings are usable without a mouse.

---

### User Story 6 - Monitor and Control Indexing (Priority: P2)

A user sees what LocalLens is doing during indexing and can pause, resume, cancel, retry failed work, reindex a file, or reindex a folder.

**Why this priority**: Indexing can be long-running; users need control and trust when the app reads large local libraries.

**Independent Test**: During indexing of a mixed library, the user can see queued, running, completed, and failed counts; pause and resume work; cancel the run; and retry a failed item without relaunching.

**Acceptance Scenarios**:

1. **Given** a folder is being indexed, **When** the user opens the menu bar popover or Settings, **Then** they see current progress, queue size, completed count, failed count, and last indexed time.
2. **Given** indexing is running, **When** the user pauses indexing, **Then** no new files start processing until the user resumes.
3. **Given** indexing is running, **When** the user cancels indexing, **Then** in-progress work stops safely and no partially indexed record is presented as complete.
4. **Given** a file or folder needs fresh indexing, **When** the user chooses reindex, **Then** LocalLens queues the selected file or folder again and updates its results after processing.

---

### User Story 7 - Understand Privacy, Storage, and Failures (Priority: P3)

A user understands that MVP processing is local by default, can review storage usage, delete or rebuild the local index, and recover from indexing failures without exposing sensitive content.

**Why this priority**: Privacy-first positioning and broad local file access require explicit trust-building and recoverability before beta use.

**Independent Test**: The user can complete first-run onboarding, read the privacy explanation, view local storage usage, export redacted diagnostics, retry failures, and confirm no remote AI provider is enabled by default.

**Acceptance Scenarios**:

1. **Given** the user launches LocalLens for the first time, **When** onboarding appears, **Then** it explains local processing, folder access, indexing data, and how to start safely.
2. **Given** the user opens Settings, **When** they view privacy and storage, **Then** they can see where local index data is retained and can delete or rebuild it.
3. **Given** indexing failures exist, **When** the user opens the failure dashboard, **Then** each failure shows a safe category, retryability, and available recovery action without raw file contents.
4. **Given** remote AI settings are present in the MVP, **When** the user views them, **Then** they are disabled or clearly experimental by default and cannot transmit data without explicit opt-in.

---

### Edge Cases

- Watched folder is deleted, renamed, moved, unavailable, or located on an external drive that is disconnected.
- User denies folder access, revokes file permissions, or the app cannot re-open a previously authorized folder.
- Recursive discovery encounters symlinks, packages, hidden folders, permission-denied directories, network volumes, or very large folder trees.
- Supported files are corrupted, password-protected, empty, extremely large, partially downloaded, or have misleading file extensions.
- PDF text extraction succeeds for some pages and fails for others.
- Local AI model files are missing, unavailable, slow, or return no useful result.
- Audio/video transcription or scene extraction fails while other indexing stages succeed.
- User pauses, cancels, quits, or force-quits the app during indexing.
- An indexed file changes between discovery, extraction, search, preview, and reveal.
- A search query is empty, extremely long, contains sensitive text, or matches many thousands of assets.
- Local index storage becomes full, corrupted, or inconsistent after an app crash.
- Remote AI provider settings exist but the network is disabled or the endpoint is unreachable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST run as a macOS menu bar application with search available from the menu bar and no required Dock window for primary use.
- **FR-002**: Users MUST be able to add, view, enable, disable, and remove watched folders.
- **FR-003**: The system MUST preserve authorized access to watched folders across app restarts and clearly request reauthorization when access cannot be restored.
- **FR-004**: The system MUST recursively discover supported media files inside watched folders while ignoring unsupported files without blocking the library.
- **FR-005**: The system MUST support discovery for at least these file types in MVP scope: PNG, JPEG, HEIC, TIFF, WebP, PDF, MP3, M4A, WAV, AAC, MP4, MOV, and M4V.
- **FR-006**: The system MUST maintain a local library index containing watched folders, media assets, extraction records, text or transcript chunks, searchable metadata, index jobs, failures, and settings.
- **FR-007**: The system MUST index screenshots and images with a thumbnail, visible text when available, visual concept metadata when available, dimensions, creation or modification dates, and searchable metadata.
- **FR-008**: The system MUST index PDFs with thumbnail, page count when available, selectable text when available, recognized text from image pages within MVP bounds when feasible, and searchable metadata.
- **FR-009**: The system MUST index audio files with duration, basic media metadata, transcript when local transcription succeeds, timestamped transcript chunks when available, and searchable metadata.
- **FR-010**: The system MUST index videos with duration, representative thumbnail or keyframes, bounded sampled-scene metadata, visible text from sampled frames when feasible, transcript when an audio track exists and local transcription succeeds, and searchable metadata.
- **FR-011**: The system MUST generate local searchable representations for text-like content, transcripts, visual labels, and semantic meaning in the default configuration.
- **FR-012**: The system MUST provide natural-language search across filenames, visible text, PDF text, transcript text, visual labels, and semantic metadata.
- **FR-013**: The system MUST display ranked search results with thumbnail when available, file name, media type, path or folder context, modified or created date when available, matched reason, and page or timestamp hint when available.
- **FR-014**: The system MUST explain each visible result match using one or more reasons: filename, visible text, PDF text, transcript, visual label, or semantic match.
- **FR-015**: Users MUST be able to preview a result, reveal it in Finder, open it with the system default behavior, copy its file path, and copy a relevant extracted snippet when available.
- **FR-016**: The system MUST show indexing progress including queue size, running state, completed count, failed count, and last indexed time.
- **FR-017**: Users MUST be able to pause, resume, cancel, retry failed indexing work, reindex one file, and reindex a watched folder.
- **FR-018**: The system MUST provide Settings for watched folders, indexing state, privacy explanation, storage usage, index deletion or rebuild, and local or experimental remote AI provider configuration.
- **FR-019**: The system MUST provide first-run onboarding that explains the privacy promise, folder access, local index retention, and how to begin indexing.
- **FR-020**: The system MUST provide a failure dashboard with safe failure categories, retryability, and recovery actions such as retry, ignore, reauthorize folder, or rebuild index.
- **FR-021**: The system MUST preserve source media files unchanged during MVP indexing, search, preview, diagnostics, and reindex operations.
- **FR-022**: The system MUST never present a partially completed or cancelled extraction as a complete indexed record.
- **FR-023**: The system MUST handle app quit and relaunch without losing completed index data or corrupting queued work.
- **FR-024**: The system MUST support keyboard operation for primary search, result navigation, preview, reveal, pause, resume, and settings flows.

### Constitutional Requirements *(mandatory for file-system or AI features)*

- **CA-001 File Authority**: LocalLens reads user-selected watched folders recursively and reads supported media files for indexing, search, preview, diagnostics, and reindexing. MVP operations MUST NOT write, rename, move, delete, transcode, or modify source media files. LocalLens may write only its own local index, thumbnails, metadata, settings, logs, and temporary derived files.
- **CA-002 Local/Remote AI**: Local inference is the default and required baseline for OCR, transcription, visual metadata, embeddings, and scene metadata. Remote AI providers, if exposed in MVP, MUST be disabled or clearly experimental by default and require explicit opt-in before transmitting any file bytes, extracted text, transcripts, filenames, prompts, embeddings, or metadata.
- **CA-003 Privacy & Retention**: The system stores local index records, thumbnails, extracted text, transcripts, visual labels, semantic metadata, failures, and settings under local app-controlled storage or a user-selected storage location. Users MUST be able to view storage usage and delete or rebuild local index data.
- **CA-004 Non-Destructive Guarantee**: Source files remain unmodified in MVP. Any future source mutation, cleanup, organization, deduplication, conversion, or deletion is out of scope for this feature and requires a separate specification with confirmation and recovery requirements.
- **CA-005 Failure & Recovery**: The system MUST define safe behavior for permission denial, stale authorization, missing folders, missing files, external drives, corrupted media, model failure, cancelled jobs, app restart, and index corruption. Recovery actions MUST include retry, ignore, reauthorize, cancel, reindex, delete index, or rebuild index where applicable.
- **CA-006 Performance Bounds**: Indexing MUST use bounded background work, bounded thumbnails, bounded video sampling, chunked transcript/text processing, and resumable queue state. Search over an already indexed 10,000-asset library SHOULD return first usable results in under 500 ms on target hardware.
- **CA-007 Observability**: Progress, failure categories, retryability, and diagnostics MUST be visible without exposing raw file contents, full extracted transcripts, sensitive text, credentials, or full paths by default.

### Key Entities *(include if feature involves data)*

- **Watched Folder**: A user-authorized folder that LocalLens may scan for supported media. Key attributes include display name, authorization state, enabled state, last scan time, and recovery status.
- **Media Asset**: A supported local file discovered in a watched folder. Key attributes include media type, path context, file identity, size, dates, thumbnail status, index status, and missing or changed state.
- **Extraction Record**: Metadata produced from a media asset, such as visible text, PDF text, transcript, visual label, keyframe scene data, duration, dimensions, page count, or confidence.
- **Searchable Chunk**: A text-like or semantic unit derived from a file, such as OCR text, document text, transcript segment, visual label group, or semantic representation, optionally tied to a page or timestamp.
- **Index Job**: A queued, running, completed, cancelled, or failed unit of indexing work for discovery, extraction, transcription, thumbnailing, semantic metadata, reindexing, or cleanup.
- **Index Failure**: A safe, user-visible failure category linked to a file or folder with retryability, time, affected stage, and recovery options.
- **Search Result**: A ranked response to a user query containing the asset, thumbnail, match reason, snippet, page or timestamp hint, and actions.
- **Provider Setting**: A local or remote inference configuration including enabled state, privacy state, credential state, endpoint trust state, and experimental status where applicable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can add a first watched folder and start indexing in under 2 minutes from first launch.
- **SC-002**: For a fixture library with at least 10 images or screenshots, 3 PDFs, 3 audio files, and 3 videos, users can retrieve at least one relevant result for visible image text, PDF text, spoken audio text, spoken video text, and sampled video scene content.
- **SC-003**: At least 90% of successful search results in MVP QA display a clear match reason such as filename, visible text, PDF text, transcript, visual label, or semantic match.
- **SC-004**: For an already indexed 10,000-asset library on target hardware, the first usable search results appear in under 500 ms for common queries.
- **SC-005**: Indexing a mixed 1,000-file library does not block menu bar search, Settings navigation, pause, resume, or cancel actions during manual QA.
- **SC-006**: Cancelling indexing during active processing leaves zero cancelled or partial records marked as complete in validation checks.
- **SC-007**: With network access disabled, default MVP indexing and search still work for local files that do not require experimental remote providers.
- **SC-008**: Source media files remain byte-for-byte unchanged after indexing, searching, previewing, and diagnostic export during MVP QA.
- **SC-009**: 100% of user-facing failure messages in MVP QA avoid raw extracted file contents, full transcripts, credentials, and sensitive raw provider responses.
- **SC-010**: Keyboard-only users can complete search, result selection, preview, reveal, pause or resume indexing, and open Settings without using a mouse.

## Assumptions

- The primary user is a Mac power user with local folders of mixed personal or professional media and willingness to grant folder access for private indexing.
- MVP scope targets macOS as a native menu bar experience; mobile apps, browser extensions, team sharing, and cloud sync are out of scope.
- Local processing is the default product promise; remote AI settings may exist only as disabled or experimental opt-in configuration in the MVP.
- Audio and video search in MVP means transcript search plus bounded sampled-scene metadata, not full frame-by-frame video understanding.
- Image/PDF search is the required alpha cutline if schedule pressure requires deferring audio/video polish.
- User-selected watched folders are the initial authority boundary even if the app later requests broader system permissions for convenience.
- Local index data may be rebuilt from source files; deleting the local index does not delete source files.
