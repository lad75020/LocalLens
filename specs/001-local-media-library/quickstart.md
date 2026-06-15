# Quickstart: LocalLens MVP Plan Validation

## Prerequisites

- macOS 26.0+.
- Xcode 26.x with Swift 6.3+.
- LocalLens repository at `/Volumes/WDBlack4TB/Code/LocalLens`.
- Optional local inference servers:
  - oMLX at `http://localhost:17998/v1`.
  - Ollama at `http://localhost:11434/v1`.
  - Hermes Agent API server at `http://localhost:8642/v1`.

## Create the Xcode Project

The implementation phase must create:

```text
LocalLens.xcodeproj
LocalLens/LocalLensApp.swift
LocalLens/Resources/LocalLens.entitlements
LocalLensTests/
LocalLensUITests/
```

Project settings:
- macOS app target, SwiftUI lifecycle.
- Swift language mode: Swift 6.
- Strict concurrency checks enabled.
- Minimum deployment target: macOS 26.0.
- App Sandbox enabled.
- User-selected file read-only entitlement enabled.
- Security-scoped bookmarks enabled.
- Network client entitlement enabled only because loopback/local provider health checks and inference calls are part of the MVP.

Use XCodeMCP for browsing/building the project after it exists and is open in Xcode.

## Expected Local Provider Health Checks

```bash
curl -s http://localhost:17998/v1/models || true
curl -s http://localhost:11434/v1/models || true
curl -s http://localhost:8642/v1/models || true
```

Provider unavailability must not prevent the app from launching or local Apple-framework indexing from working.

## Manual MVP Smoke Flow

1. Launch LocalLens.
2. Complete onboarding and read the privacy explanation.
3. Add a watched folder containing fixture screenshots/images/PDFs/audio/videos.
4. Confirm indexing starts and progress is visible.
5. Pause indexing; verify no new jobs start.
6. Resume indexing; verify jobs continue.
7. Search for:
   - visible screenshot text
   - PDF text
   - an object/scene label
   - audio transcript text
   - video transcript or sampled scene text
8. Select a result with keyboard arrows.
9. Press Space to preview.
10. Reveal in Finder.
11. Copy a relevant snippet.
12. Open Settings → Privacy & Storage and verify index size and delete/rebuild controls.
13. Export diagnostics and verify no raw extracted text, transcripts, credentials, full paths, or raw provider bodies are included.

## Automated Validation Targets

Future tasks should create XCTest coverage for:
- Security-scoped bookmark save/restore/stale behavior.
- Recursive discovery and supported type filtering.
- Non-destructive byte-for-byte source file checks.
- Index queue pause/resume/cancel/retry/relaunch recovery.
- Extractor fixtures for image/PDF/audio/video.
- Provider URL normalization and transport blocking.
- Prompt template injection resistance and size bounds.
- Search ranking and match reason generation.
- Redacted diagnostics export.
- 10,000-asset search performance fixture.

## Build Verification

After project creation, verify with XCodeMCP build tools where possible. CLI fallback command:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
```

Do not mark implementation complete until the app target and test target build successfully.

## Implementation Validation Log

### 2026-06-15 Foundation Pass

Generated `LocalLens.xcodeproj` with XcodeGen from `project.yml`, using Swift 6 strict concurrency, macOS 26.0 deployment target, app sandbox, read-only user-selected file access, app-scope security-scoped bookmarks, network client entitlement, and SQLite linked through `libsqlite3.tbd`.

Build command:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
```

Result: `** BUILD SUCCEEDED **`.

Test command:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
```

Result: `** TEST SUCCEEDED **` with 8 unit tests and 3 UI smoke tests passing. The run emitted unrelated `linkd.autoShortcut` connection warnings and LLDB debugger-version warnings, but XCTest completed successfully.

### 2026-06-15 Phase 2 Repository and Inference Security Pass

Completed foundational repository protocols, SQLite-backed repositories, dependency container wiring, and inference security coverage for T016, T017, T027, T029, and T030.

Build command:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
```

Result: `** BUILD SUCCEEDED **`.

Test command:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
```

Result: `** TEST SUCCEEDED **` with 13 unit tests and 3 UI smoke tests passing. The run emitted unrelated `linkd.autoShortcut`, detached-signature, and LLDB debugger-version warnings, but XCTest completed successfully.
