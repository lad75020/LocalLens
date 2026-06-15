---
goal: LocalLens MVP Feature Plan for Private macOS Media Library Menu Bar App
version: 1.0
date_created: 2026-06-15
last_updated: 2026-06-15
owner: Laurent
status: Planned
tags: [feature, mvp, macos, swiftui, local-ai, media-library, menubar]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

LocalLens is a private macOS menu bar application that indexes user-selected local folders containing screenshots, images, PDFs, audio, and videos. The MVP enables local-first search by meaning, OCR text, detected visual concepts, audio transcript, and video scene metadata without uploading user files to external services.

The MVP goal is a working native macOS app that can: select and remember one or more folders, index supported media in the background, generate searchable local metadata, provide a fast menu-bar search UI, preview results with Quick Look, and reveal results in Finder.

## MVP Product Promise

> “Drop a folder into LocalLens and privately find any screenshot, image, PDF, audio clip, or video by what it contains — not what it is named.”

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-001**: The app MUST run as a macOS menu bar app with no mandatory Dock window.
- **REQ-002**: The app MUST allow the user to add at least one watched folder using `NSOpenPanel`.
- **REQ-003**: The app MUST persist access to watched folders using security-scoped bookmarks.
- **REQ-004**: The app MUST recursively discover supported files under watched folders.
- **REQ-005**: The app MUST index screenshots and images with thumbnail, OCR text, visual labels, dimensions, creation date, and perceptual/search embedding metadata.
- **REQ-006**: The app MUST index PDFs with page count, extracted selectable text, OCR fallback for image pages if feasible, thumbnail, and searchable embedding metadata.
- **REQ-007**: The app MUST index audio files with duration, basic metadata, transcript, and searchable transcript embedding metadata.
- **REQ-008**: The app MUST index videos with duration, thumbnail/keyframes, basic scene labels, optional OCR from sampled frames, optional transcript when an audio track exists, and searchable embedding metadata.
- **REQ-009**: The app MUST provide natural-language search across filenames, OCR text, PDF text, transcripts, visual labels, and embeddings.
- **REQ-010**: The app MUST display ranked search results with thumbnail, file name, matched reason, media type, timestamp/page hint when available, and folder path.
- **REQ-011**: The app MUST support Quick Look preview from each search result.
- **REQ-012**: The app MUST support “Reveal in Finder” from each search result.
- **REQ-013**: The app MUST show indexing progress, current queue size, completed count, failed count, and last indexed time.
- **REQ-014**: The app MUST support pause, resume, and cancel indexing.
- **REQ-015**: The app MUST support reindexing a single file and reindexing a watched folder.
- **REQ-016**: The app MUST not rename, move, delete, or modify user media files in the MVP.

### Local AI Requirements

- **AI-001**: OCR MUST use local Apple Vision APIs where possible.
- **AI-002**: Audio transcription SHOULD use local WhisperKit or an equivalent local transcription engine.
- **AI-003**: Embeddings MUST be generated locally in the default configuration.
- **AI-004**: The app MAY support a pluggable embedding provider interface, but MVP UI MUST clearly label any non-local provider as disabled or experimental.
- **AI-005**: Visual concept extraction SHOULD start with local Vision image classification and/or image feature prints.
- **AI-006**: Video scene search MUST be implemented as sampled keyframe indexing in the MVP, not full frame-by-frame analysis.

### Privacy & Security Requirements

- **SEC-001**: No user file bytes, extracted text, transcripts, embeddings, or metadata may leave the Mac by default.
- **SEC-002**: Network access for AI providers MUST be absent or disabled by default in MVP builds.
- **SEC-003**: Security-scoped folder access MUST be started only for active indexing or preview operations and stopped afterwards.
- **SEC-004**: Local index storage MUST remain inside the app container/Application Support unless the user explicitly chooses another location.
- **SEC-005**: Error messages shown in UI MUST not include large raw file contents, transcript chunks, or sensitive extracted text.
- **SEC-006**: Logs MUST redact full paths by default in user-facing diagnostics; debug logs may show paths behind an explicit setting.
- **SEC-007**: The app MUST include a privacy screen explaining that all MVP processing is local.

### Performance Requirements

- **PER-001**: The app MUST remain responsive while indexing large folders.
- **PER-002**: Heavy disk IO, media decoding, OCR, transcription, embedding generation, and video keyframe extraction MUST run off the MainActor.
- **PER-003**: The indexer MUST process files through a bounded queue with configurable concurrency.
- **PER-004**: The first usable search result for an already indexed library SHOULD return in under 500 ms for 10,000 indexed assets on Apple Silicon.
- **PER-005**: The app MUST avoid loading full videos, large PDFs, or high-resolution images into memory when lower-cost metadata/keyframes are sufficient.
- **PER-006**: The app MUST store thumbnails at bounded sizes.

### UX Requirements

- **UX-001**: The menu bar popover MUST provide a search field as the primary interaction.
- **UX-002**: Empty state MUST guide the user to add a folder.
- **UX-003**: Search results MUST explain why a result matched: filename, OCR, transcript, visual label, PDF text, or semantic match.
- **UX-004**: Indexing status MUST be visible but not noisy.
- **UX-005**: The MVP MUST include a Settings window for watched folders, indexing, privacy, and storage.
- **UX-006**: The app MUST support keyboard-only search, selection, preview, and reveal actions.

### Technical Constraints

- **CON-001**: Target platform is macOS 26.0+ unless project requirements later choose broader support.
- **CON-002**: Use Swift 6+ and SwiftUI for app UI.
- **CON-003**: Use AppKit bridging where needed for menu bar, Quick Look, Finder reveal, and file panels.
- **CON-004**: Use SQLite or SwiftData for metadata persistence; choose SQLite if vector search requires custom tables/extensions.
- **CON-005**: Use a separate indexing actor/service, not a view-model-bound indexing pipeline.
- **CON-006**: MVP indexing must be deterministic and resumable after app restart.
- **CON-007**: MVP must not require a backend service.

## 2. MVP Scope

### Included in MVP

- Menu bar app shell.
- Folder onboarding and security-scoped bookmarks.
- Recursive file discovery for: `png`, `jpg`, `jpeg`, `heic`, `tiff`, `webp`, `pdf`, `mp3`, `m4a`, `wav`, `aac`, `mp4`, `mov`, `m4v`.
- Local metadata database.
- Image/screenshot OCR and visual label extraction.
- PDF text extraction and thumbnail generation.
- Audio transcription using local engine.
- Video thumbnail/keyframe sampling and optional audio-track transcription.
- Local embeddings for text-like content and visual labels.
- Unified natural-language search UI.
- Quick Look preview and Reveal in Finder.
- Pause/resume/cancel indexing.
- Basic failure reporting.

### Explicitly Excluded from MVP

- Cloud sync.
- iCloud library support beyond normal file access.
- Team sharing.
- Destructive file organization, renaming, moving, deduplication, or cleanup.
- Full object segmentation.
- Face recognition or identity clustering.
- Full-frame video analysis.
- In-app model marketplace.
- Mobile/iOS companion app.
- Browser extension.
- External network AI providers enabled by default.

## 3. User Stories

| Story | User Need | Acceptance Criteria |
|---|---|---|
| **US-001 Add Library Folder** | As a user, I can add a folder of media so LocalLens can index it. | Folder appears in Settings; bookmark survives restart; user can remove folder; index queue starts. |
| **US-002 Search Screenshot Text** | As a user, I can search text visible inside screenshots. | OCR text from images is indexed; search query returns matching screenshots; matched text reason is displayed. |
| **US-003 Search by Meaning** | As a user, I can search concepts like “receipt from Apple” or “terminal error screen” even when filenames do not match. | Query ranks semantically relevant assets using local metadata/embeddings; UI identifies semantic match. |
| **US-004 Search PDFs** | As a user, I can search across PDFs in watched folders. | PDF selectable text is indexed; result shows PDF name, page count, and text match reason. |
| **US-005 Search Audio** | As a user, I can search what was said in an audio recording. | Audio transcript is indexed; search returns audio file with transcript snippet. |
| **US-006 Search Video Scene** | As a user, I can find a video by a sampled scene or spoken words. | Video keyframe labels/OCR and transcript are indexed; result shows keyframe thumbnail and match reason. |
| **US-007 Preview Result** | As a user, I can inspect a result without leaving LocalLens. | Space/Enter or Preview button opens Quick Look for selected result. |
| **US-008 Reveal Result** | As a user, I can jump to the original file. | Reveal button opens Finder with the file selected. |
| **US-009 Manage Indexing** | As a user, I can see and control indexing. | UI shows queued/running/completed/failed; pause/resume/cancel work. |

## 4. Implementation Steps

### Implementation Phase 1 — App Shell, Storage, Folder Access

- **GOAL-001**: Create a secure, responsive macOS menu bar foundation with persistent folder access and metadata storage.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-001** | Create project at `/Volumes/WDBlack4TB/Code/LocalLens/LocalLens.xcodeproj` or equivalent Swift Package/XcodeGen setup with app target `LocalLens` and test target `LocalLensTests`. |  |  |
| **TASK-002** | Implement `LocalLensApp.swift` using `MenuBarExtra` as the primary app entry and a Settings scene for full configuration. |  |  |
| **TASK-003** | Add app sandbox entitlements with user-selected read-only file access unless write access is later required. |  |  |
| **TASK-004** | Implement `FolderAccessService` for `NSOpenPanel`, security-scoped bookmark creation, bookmark resolution, stale bookmark refresh, and removal. |  |  |
| **TASK-005** | Implement `LibraryStore` persistence with tables/models for watched folders, media assets, extraction records, embeddings, index jobs, failures, and app settings. |  |  |
| **TASK-006** | Implement `MediaAsset` data model with stable asset ID, file URL bookmark/path, content type, file size, creation/modification dates, hash or file identity, thumbnail path, index status, and last indexed timestamp. |  |  |
| **TASK-007** | Implement `SettingsView` with watched folder list, add/remove folder actions, privacy copy, storage location display, and reset index button. |  |  |
| **TASK-008** | Implement `MenuPopoverView` empty state with “Add Folder”, “Open Settings”, and privacy-first explanation. |  |  |
| **TASK-009** | Add unit tests for bookmark persistence, model creation, watched folder CRUD, and app settings defaults. |  |  |

**Phase 1 Completion Criteria**

- App launches as a menu bar app.
- User can add/remove a watched folder.
- Folder access persists after restart.
- Metadata store initializes and can persist watched folders.
- No indexing pipeline is required yet.

### Implementation Phase 2 — File Discovery and Index Queue

- **GOAL-002**: Discover supported media safely and enqueue deterministic, resumable indexing jobs.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-010** | Implement `SupportedMediaType` enum for images, PDFs, audio, and video with UTType-based detection and extension fallback. |  |  |
| **TASK-011** | Implement `FileDiscoveryService` that recursively enumerates watched folders using `FileManager.DirectoryEnumerator` while skipping packages, hidden folders, unsupported files, and app index storage. |  |  |
| **TASK-012** | Implement large-library safeguards: progress reporting, cancellation checks, symlink loop prevention, and max initial batch warning without silently truncating work. |  |  |
| **TASK-013** | Implement `IndexJobQueue` as an actor with pending/running/completed/failed states and bounded concurrency. |  |  |
| **TASK-014** | Implement file identity change detection using file size, modification date, content hash for small files, and persistent file resource identifiers where available. |  |  |
| **TASK-015** | Implement pause, resume, cancel, retry failed, reindex file, and reindex folder commands. |  |  |
| **TASK-016** | Implement `IndexingStatusView` in the menu popover and Settings window. |  |  |
| **TASK-017** | Add tests for media type detection, recursive discovery, queue transitions, cancellation, and duplicate file detection. |  |  |

**Phase 2 Completion Criteria**

- Adding a folder discovers supported files.
- Files are persisted as assets with pending jobs.
- Indexing can be paused, resumed, cancelled, and retried.
- UI remains responsive during discovery.

### Implementation Phase 3 — Image, Screenshot, and PDF Indexing

- **GOAL-003**: Deliver the first valuable search experience: find screenshots/images/PDFs by visible text, PDF text, labels, and semantic meaning.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-018** | Implement `ThumbnailService` to generate bounded thumbnails for images and first-page PDF previews. |  |  |
| **TASK-019** | Implement `ImageOCRService` using Vision `VNRecognizeTextRequest` for image and screenshot OCR. |  |  |
| **TASK-020** | Implement `ImageVisualLabelService` using local Vision classification and/or image feature-print metadata. |  |  |
| **TASK-021** | Implement `PDFTextExtractionService` using PDFKit for selectable text extraction, page count, and metadata. |  |  |
| **TASK-022** | Implement optional PDF OCR fallback for first N image-only pages with clear MVP bounds. |  |  |
| **TASK-023** | Implement `EmbeddingService` interface with a local default provider for text chunks and labels. |  |  |
| **TASK-024** | Implement `ChunkingService` for OCR/PDF text with stable chunk IDs, source type, page number if available, and snippet generation. |  |  |
| **TASK-025** | Persist extracted OCR text, PDF text chunks, visual labels, thumbnails, and embeddings. |  |  |
| **TASK-026** | Add tests with fixture image, screenshot, and PDF files to validate extraction and persistence. |  |  |

**Phase 3 Completion Criteria**

- Images and PDFs are fully indexable.
- OCR/PDF text appears in the database.
- Thumbnails are generated.
- Search metadata is available for Phase 4.

### Implementation Phase 4 — Audio and Video Indexing

- **GOAL-004**: Add MVP support for transcript and sampled-scene search across audio and video.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-027** | Implement `AudioMetadataService` using AVFoundation for duration, format, sample rate, and basic metadata. |  |  |
| **TASK-028** | Integrate local transcription through `TranscriptionService` with a WhisperKit-backed implementation or adapter. |  |  |
| **TASK-029** | Implement transcript chunking with timestamps, snippets, and embeddings. |  |  |
| **TASK-030** | Implement `VideoMetadataService` using AVFoundation for duration, dimensions, codec, and audio-track presence. |  |  |
| **TASK-031** | Implement `VideoKeyframeService` that samples frames at deterministic intervals and/or scene-change approximations with bounded maximum frames per video. |  |  |
| **TASK-032** | Run OCR and visual label extraction on sampled video keyframes only. |  |  |
| **TASK-033** | If video has audio, enqueue a transcription job using the same transcript pipeline as audio files. |  |  |
| **TASK-034** | Persist video keyframe thumbnails, timestamped visual labels, OCR, transcript chunks, and embeddings. |  |  |
| **TASK-035** | Add tests with short audio and video fixtures for metadata extraction, transcript persistence, and keyframe sampling bounds. |  |  |

**Phase 4 Completion Criteria**

- Audio files can be found by transcript text and semantic transcript search.
- Videos can be found by transcript, sampled keyframe OCR, and visual labels.
- Long media files do not cause memory spikes or UI hangs.

### Implementation Phase 5 — Search Ranking and Result UI

- **GOAL-005**: Provide a polished menu bar search UX with ranked, explainable, actionable results.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-036** | Implement `SearchService` with lexical search across file names, OCR text, PDF text, transcripts, and visual labels. |  |  |
| **TASK-037** | Implement semantic search over local embeddings with query embedding generation. |  |  |
| **TASK-038** | Implement hybrid ranking combining lexical score, semantic score, recency, file type, and exact filename boosts. |  |  |
| **TASK-039** | Implement `SearchResult` model with asset ID, rank score, matched field, match explanation, snippet, thumbnail, timestamp/page hint, and actions. |  |  |
| **TASK-040** | Implement menu popover search field with debounced queries, keyboard navigation, and loading/empty/error states. |  |  |
| **TASK-041** | Implement result list with thumbnail, media badge, match explanation, path, and modified date. |  |  |
| **TASK-042** | Implement Quick Look preview for selected result using AppKit/QuickLook bridging. |  |  |
| **TASK-043** | Implement Reveal in Finder action with `NSWorkspace.activateFileViewerSelecting`. |  |  |
| **TASK-044** | Implement “Copy path”, “Copy text snippet/transcript”, and “Open” actions. |  |  |
| **TASK-045** | Add search tests for ranking behavior, matched-reason generation, empty libraries, and deleted files. |  |  |

**Phase 5 Completion Criteria**

- User can search from the menu bar and get useful ranked results.
- Every result explains why it matched.
- Preview and Reveal in Finder work reliably.

### Implementation Phase 6 — Reliability, Privacy, and MVP Polish

- **GOAL-006**: Make the app safe, understandable, testable, and ready for a private beta.

| Task | Description | Completed | Date |
|---|---|---:|---|
| **TASK-046** | Implement failure dashboard showing failed files, failure reason category, retry action, and “ignore” action. |  |  |
| **TASK-047** | Implement first-run onboarding with three steps: privacy promise, add folder, start indexing. |  |  |
| **TASK-048** | Implement local storage usage display and thumbnail/index cleanup command. |  |  |
| **TASK-049** | Implement app-wide cancellation-safe indexing with cleanup of partial records. |  |  |
| **TASK-050** | Add explicit privacy screen: “All indexing is local in MVP; no uploads.” |  |  |
| **TASK-051** | Add user-facing diagnostics export that redacts sensitive extracted text and full paths by default. |  |  |
| **TASK-052** | Add app icon, menu bar symbol, empty-state illustration, and minimal Liquid Glass/Tahoe-friendly visual polish. |  |  |
| **TASK-053** | Run manual QA on a fixture library containing at least 10 images/screenshots, 3 PDFs, 3 audio files, and 3 videos. |  |  |
| **TASK-054** | Run performance QA on a folder with at least 1,000 mixed files and confirm UI remains responsive. |  |  |
| **TASK-055** | Run privacy QA confirming no network requests are made during indexing/search in default MVP configuration. |  |  |

**Phase 6 Completion Criteria**

- App is usable by a private beta user without developer intervention.
- Failures are visible and recoverable.
- Privacy posture is clear.
- Manual and automated MVP checks pass.

## 5. Proposed Architecture

### Modules

| Module | Responsibility |
|---|---|
| `AppShell` | `MenuBarExtra`, Settings scene, lifecycle, commands. |
| `FolderAccess` | User folder selection and security-scoped bookmarks. |
| `MediaDiscovery` | Recursive scanning, UTType detection, file identity. |
| `IndexingCore` | Job queue, cancellation, retry, progress, persistence orchestration. |
| `Extractors` | Image OCR, visual labels, PDF text, audio transcription, video keyframes. |
| `Embeddings` | Local embedding provider, chunking, vector persistence/search. |
| `Search` | Lexical search, semantic search, hybrid ranking, snippets. |
| `PreviewActions` | Quick Look, Finder reveal, open/copy actions. |
| `Storage` | SQLite/SwiftData database, thumbnail store, model files, migrations. |
| `Diagnostics` | Redacted logs, failure reports, privacy checks. |

### Key Services

- `FolderAccessService`
- `LibraryStore`
- `FileDiscoveryService`
- `IndexJobQueue`
- `IndexingOrchestrator`
- `ThumbnailService`
- `ImageOCRService`
- `ImageVisualLabelService`
- `PDFTextExtractionService`
- `AudioMetadataService`
- `TranscriptionService`
- `VideoMetadataService`
- `VideoKeyframeService`
- `EmbeddingService`
- `SearchService`
- `QuickLookPreviewService`
- `FinderRevealService`

### Persistence Model

| Entity/Table | Fields |
|---|---|
| `watched_folders` | `id`, `displayName`, `bookmarkData`, `addedAt`, `lastScanAt`, `enabled` |
| `media_assets` | `id`, `folderId`, `pathHash`, `relativePath`, `type`, `uti`, `size`, `createdAt`, `modifiedAt`, `fileIdentity`, `thumbnailPath`, `indexStatus`, `lastIndexedAt` |
| `extractions` | `id`, `assetId`, `kind`, `text`, `labelsJson`, `pageNumber`, `timestampSeconds`, `confidence`, `createdAt` |
| `text_chunks` | `id`, `assetId`, `extractionId`, `sourceKind`, `chunkText`, `snippet`, `pageNumber`, `timestampSeconds` |
| `embeddings` | `id`, `chunkId`, `provider`, `model`, `dimension`, `vectorBlob`, `createdAt` |
| `index_jobs` | `id`, `assetId`, `jobType`, `status`, `attempts`, `lastErrorCode`, `createdAt`, `updatedAt` |
| `failures` | `id`, `assetId`, `stage`, `errorCode`, `safeMessage`, `retryable`, `createdAt` |
| `settings` | `key`, `value` |

## 6. Alternatives

- **ALT-001**: Use Spotlight metadata only. Rejected because Spotlight does not provide consistent app-controlled multimodal OCR/transcript/semantic ranking.
- **ALT-002**: Build as a full document-management app first. Rejected because the menu bar search wedge is smaller and more useful for MVP validation.
- **ALT-003**: Use cloud AI for embeddings/transcription. Rejected for MVP because the core product promise is private local AI.
- **ALT-004**: Start with only screenshots/images. Rejected because the product concept explicitly includes PDFs, audio, and video; however, implementation phases still sequence images/PDFs before audio/video.
- **ALT-005**: Use full frame-by-frame video understanding. Rejected because it is too expensive for MVP; sampled keyframes and transcripts provide useful scene search at lower cost.

## 7. Dependencies

- **DEP-001**: Swift 6+ and Xcode project setup.
- **DEP-002**: SwiftUI and AppKit for menu bar, settings, file panels, Quick Look, and Finder actions.
- **DEP-003**: Foundation and UniformTypeIdentifiers for file metadata and type detection.
- **DEP-004**: Vision for OCR and image classification/feature extraction.
- **DEP-005**: PDFKit for PDF parsing and thumbnails.
- **DEP-006**: AVFoundation for audio/video metadata, thumbnails, and audio extraction.
- **DEP-007**: WhisperKit or local transcription adapter for audio/video transcript generation.
- **DEP-008**: Local embedding model/provider, preferably MLX/Core ML compatible.
- **DEP-009**: SQLite/SwiftData persistence layer.
- **DEP-010**: QuickLook for result previews.

## 8. Files

If bootstrapping a new project, create or modify these files under `/Volumes/WDBlack4TB/Code/LocalLens/`:

- **FILE-001**: `LocalLens/LocalLensApp.swift` — app entry point and menu bar setup.
- **FILE-002**: `LocalLens/AppShell/MenuPopoverView.swift` — primary search popover.
- **FILE-003**: `LocalLens/AppShell/SettingsView.swift` — settings, folders, privacy, storage.
- **FILE-004**: `LocalLens/FolderAccess/FolderAccessService.swift` — folder picking and bookmarks.
- **FILE-005**: `LocalLens/Storage/LibraryStore.swift` — persistence facade.
- **FILE-006**: `LocalLens/Storage/Schema.swift` — database schema/models.
- **FILE-007**: `LocalLens/MediaDiscovery/SupportedMediaType.swift` — UTType mapping.
- **FILE-008**: `LocalLens/MediaDiscovery/FileDiscoveryService.swift` — recursive discovery.
- **FILE-009**: `LocalLens/Indexing/IndexJobQueue.swift` — queue actor.
- **FILE-010**: `LocalLens/Indexing/IndexingOrchestrator.swift` — stage orchestration.
- **FILE-011**: `LocalLens/Extractors/ThumbnailService.swift` — thumbnails.
- **FILE-012**: `LocalLens/Extractors/ImageOCRService.swift` — image OCR.
- **FILE-013**: `LocalLens/Extractors/ImageVisualLabelService.swift` — image labels/features.
- **FILE-014**: `LocalLens/Extractors/PDFTextExtractionService.swift` — PDF indexing.
- **FILE-015**: `LocalLens/Extractors/AudioMetadataService.swift` — audio metadata.
- **FILE-016**: `LocalLens/Extractors/TranscriptionService.swift` — local transcription interface and implementation.
- **FILE-017**: `LocalLens/Extractors/VideoMetadataService.swift` — video metadata.
- **FILE-018**: `LocalLens/Extractors/VideoKeyframeService.swift` — keyframe sampling.
- **FILE-019**: `LocalLens/Embeddings/EmbeddingService.swift` — embedding provider interface.
- **FILE-020**: `LocalLens/Embeddings/ChunkingService.swift` — text chunking.
- **FILE-021**: `LocalLens/Search/SearchService.swift` — hybrid search.
- **FILE-022**: `LocalLens/Search/SearchResult.swift` — result model.
- **FILE-023**: `LocalLens/PreviewActions/QuickLookPreviewService.swift` — Quick Look bridge.
- **FILE-024**: `LocalLens/PreviewActions/FinderRevealService.swift` — Finder actions.
- **FILE-025**: `LocalLens/Diagnostics/DiagnosticsService.swift` — redacted diagnostics.
- **FILE-026**: `LocalLensTests/*` — unit and integration tests.

## 9. Testing

### Automated Tests

- **TEST-001**: Folder bookmark creation, resolution, stale refresh, and removal.
- **TEST-002**: Supported file type detection for all MVP extensions.
- **TEST-003**: Recursive discovery skips unsupported files, hidden folders, packages, and symlink loops.
- **TEST-004**: Queue state transitions: pending → running → completed, pending → cancelled, running → failed → retry.
- **TEST-005**: Image OCR fixture produces non-empty extracted text.
- **TEST-006**: PDF text fixture produces expected text and page count.
- **TEST-007**: Audio fixture produces transcript chunks when local transcription is available.
- **TEST-008**: Video fixture produces bounded keyframes and duration metadata.
- **TEST-009**: Search returns exact filename matches above weak semantic matches.
- **TEST-010**: Search result matched reason is populated for filename, OCR, PDF text, transcript, visual label, and semantic match.
- **TEST-011**: Deleted or moved files are marked missing and do not crash preview/search.
- **TEST-012**: Cancellation leaves no half-written index records visible as complete.

### Manual QA

- **QA-001**: Fresh install opens menu bar popover and explains privacy promise.
- **QA-002**: Add a folder with mixed media and watch progress update.
- **QA-003**: Search for text visible in a screenshot.
- **QA-004**: Search for text inside a PDF.
- **QA-005**: Search for spoken words inside an audio recording.
- **QA-006**: Search for spoken words or sampled visual content inside a video.
- **QA-007**: Preview a result with Quick Look.
- **QA-008**: Reveal a result in Finder.
- **QA-009**: Quit and relaunch; watched folders and indexed results remain available.
- **QA-010**: Disable network and confirm default indexing/search still works.
- **QA-011**: Index a 1,000-file mixed folder and confirm UI responsiveness.

## 10. Risks & Assumptions

- **RISK-001**: Local embedding model integration may be the hardest MVP dependency. Mitigation: define `EmbeddingService` interface early and allow a simple local lexical/BM25 fallback while embedding provider is finalized.
- **RISK-002**: Audio/video indexing can dominate runtime and battery. Mitigation: make transcription/keyframe jobs lower priority, bounded, cancellable, and visibly queued.
- **RISK-003**: Vision classification may produce weak object labels for arbitrary screenshots. Mitigation: rely on OCR and semantic text first; treat visual labels as supporting signals.
- **RISK-004**: Security-scoped bookmark handling can fail for moved folders or external drives. Mitigation: show folder health and reauthorize flow.
- **RISK-005**: Large PDFs/videos can cause memory spikes. Mitigation: stream metadata and sample pages/frames with hard limits.
- **RISK-006**: Search quality may feel poor without careful ranking. Mitigation: hybrid ranking and explicit matched reasons from the first version.
- **RISK-007**: App Store sandboxing may complicate local model file storage and folder access. Mitigation: design with sandbox compliance from Phase 1.
- **ASSUMPTION-001**: The initial target user is a power user with local folders of mixed media and comfort granting folder access.
- **ASSUMPTION-002**: The MVP can require Apple Silicon for best local AI performance.
- **ASSUMPTION-003**: The MVP can ship as direct distribution/TestFlight before Mac App Store submission decisions.
- **ASSUMPTION-004**: Video scene search in MVP means sampled keyframes plus transcript, not full semantic video understanding.

## 11. Milestones

| Milestone | Target Outcome | Suggested Duration |
|---|---|---:|
| **M1 Foundation** | Menu bar app, folder access, database, no indexing. | 1 week |
| **M2 Discovery Queue** | Recursive discovery and resumable job queue. | 1 week |
| **M3 Image/PDF Searchable Index** | OCR, PDF text, thumbnails, local embeddings. | 2 weeks |
| **M4 Audio/Video Indexing** | Transcripts and sampled keyframe scene metadata. | 2 weeks |
| **M5 Search UX** | Ranked explainable search, Quick Look, Finder reveal. | 1 week |
| **M6 Beta Polish** | Reliability, privacy screen, diagnostics, performance QA. | 1 week |

Total MVP estimate: **8 weeks** for a polished private beta, or **4-5 weeks** for a narrower image/PDF-first alpha with audio/video behind experimental flags.

## 12. MVP Cutline If Time Slips

If the project exceeds schedule, preserve the product promise with this cutline:

1. Keep: menu bar app, folder access, image/screenshot OCR, PDF text, local search, thumbnails, Quick Look, Finder reveal.
2. Keep as beta: local embeddings for text chunks.
3. Defer: audio transcription UI polish.
4. Defer: video transcript and scene indexing.
5. Defer: advanced visual object detection.

The smallest compelling alpha is: **“Private Spotlight for screenshots and PDFs.”**

## 13. Related Specifications / Further Reading

- `/Volumes/WDBlack4TB/Code/idea-shortlist.json` — idea generation source.
- Existing reference projects to inspect for reusable patterns:
  - `/Volumes/WDBlack4TB/Code/Screenshot2Image`
  - `/Volumes/WDBlack4TB/Code/Image-Renamer`
  - `/Volumes/WDBlack4TB/Code/VideoScreenshot`
  - `/Volumes/WDBlack4TB/Code/WhisperKit`
  - `/Volumes/WDBlack4TB/Code/ModelTrainer`
- Apple frameworks likely needed: SwiftUI, AppKit, Vision, PDFKit, AVFoundation, QuickLook, UniformTypeIdentifiers, Security-scoped bookmarks.
