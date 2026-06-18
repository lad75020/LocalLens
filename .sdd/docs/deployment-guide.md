# Deployment Guide

## Prerequisites

LocalLens is a native macOS desktop application. The repository evidence does not define a server deployment, Docker image, cloud infrastructure, or CI/CD deployment pipeline.

### Software Requirements

| Software | Minimum Version | Purpose |
|----------|-----------------|---------|
| macOS | 26.0 | Target runtime platform |
| Xcode | Version with Swift 6 and macOS 26 SDK support | Build, test, archive, sign |
| Swift | 6.0 | Application language mode |
| SQLite3 | System library | Local persistence and FTS5 |
| Optional oMLX service | OpenAI-compatible endpoint | Local descriptive generation when selected |
| Optional Ollama service | OpenAI-compatible endpoint | Local descriptive generation and fixed embeddings |
| Optional Hermes Agent service | OpenAI-compatible endpoint | Hermes profile-backed inference and Office summaries |

### Infrastructure Requirements

No external infrastructure is required for the base desktop app. Provider-backed features require only the provider endpoints configured on the user's machine or explicitly configured by the user.

### Required Credentials

- Provider credentials, when required, must be stored through the app credential flow and Keychain.
- Do not place provider secrets in command lines, documentation examples, source files, or shell history.
- Apple Developer signing and notarization credentials are required for public distribution, but this repository evidence does not include signing or notarization automation.

## Build and Release

### Local Build

```bash
cd /Volumes/WDBlack4TB/Code/LocalLens
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
```

### Local Test

```bash
cd /Volumes/WDBlack4TB/Code/LocalLens
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
```

### Archive for Distribution

Use Xcode Organizer or an equivalent `xcodebuild archive` command with a real signing setup. The repository's project settings show manual signing with `CODE_SIGN_IDENTITY = -`, which is appropriate for local development but not enough for public distribution.

Example archive command shape:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -configuration Release -destination 'generic/platform=macOS' archive -archivePath build/LocalLens.xcarchive
```

Signing, export options, notarization, and stapling must be configured according to the intended distribution channel. The repository does not currently define an `ExportOptions.plist`, notarization script, or CI pipeline.

## Deployment Process

### Development Deployment

1. Build the app from Xcode or `xcodebuild`.
2. Run the app locally from Xcode or the built product.
3. Add watched folders from the UI.
4. Configure local providers only if provider-backed indexing is being tested.
5. Run tests before handing a build to another user.

### Manual Release Process

1. Confirm the working tree contains only intended source and documentation changes.
2. Run the full build and test commands.
3. Archive the `LocalLens` scheme in Release configuration.
4. Sign with the appropriate Developer ID or distribution identity.
5. Notarize and staple the app if distributing outside the Mac App Store.
6. Package the notarized app according to the chosen distribution channel.
7. Perform a smoke test on a clean macOS user account or test machine.

### Rollback

The repository does not define an automated rollback mechanism. For manually distributed builds:

1. Keep the previous signed and notarized artifact.
2. If a release is bad, stop distributing the new artifact.
3. Redistribute the previous known-good artifact.
4. Advise users to rebuild or delete the LocalLens local index only if the release changed derived data compatibility and the app cannot repair it automatically.

## Health Checks

LocalLens has no HTTP health endpoint. Use application-level checks instead.

| Check | Expected Result | Evidence Source |
|-------|-----------------|-----------------|
| App launches | `LocalLens` appears as a menu bar extra | `LocalLensApp` uses `MenuBarExtra` |
| Database opens | Local app support directory is created and SQLite opens | `LocalLensDatabase` initializer |
| Migration runs | Core tables, FTS5 table, generated content table exist | `MigrationV1` and additive migrations |
| Search UI responds | Popover accepts query and shows results or empty state | Search UI and UI tests |
| Folder authorization works | Added folder persists or shows reauthorization need | Folder access tests and specs |
| Provider readiness displays | Settings shows model/profile/transport readiness | Provider readiness services and tests |
| Indexing is responsive | Queue progress is visible and cancellable | Indexing runner, progress store, tests |
| Source files remain unchanged | Index/search/preview/diagnostics do not mutate sources | Privacy/security tests |

## Monitoring and Diagnostics

LocalLens uses local app state rather than server logs or metrics endpoints.

- Use Settings and the failure dashboard for queued/running/completed/failed counts and recovery actions.
- Use diagnostic export for redacted operational state.
- Diagnostics must not include credentials, raw prompts, raw provider bodies, full paths, full extracted text, or full generated descriptions/summaries by default.
- Provider readiness labels identify missing credentials, blocked transport, stale profile/model selections, and missing fixed embedding model.

## Operational Procedures

### Reindex a Folder

1. Open Settings.
2. Select the watched folder.
3. Choose reindex.
4. Monitor queue progress and failures.

### Retry Failed Work

1. Open the failure dashboard.
2. Review the safe category and retryability.
3. Fix the underlying issue, such as reauthorizing a folder or selecting a provider model.
4. Retry the failed job.

### Delete or Rebuild the Local Index

1. Open Settings.
2. Use storage/privacy controls to delete or rebuild local index data.
3. Confirm the action.
4. Reindex watched folders as needed.

This affects LocalLens-derived data only. Source media and Office files must not be deleted or modified by LocalLens.

### Repair Provider Readiness

1. Confirm the provider endpoint is reachable.
2. Refresh model or profile discovery in Settings.
3. Select a valid Ollama or oMLX generation model when using those providers for descriptive enrichment.
4. Select a valid Hermes profile before Hermes-backed work.
5. Ensure Ollama exposes `qwen3-embedding:4b` for embeddings.
6. Retry the affected stage.

### Storage Location

`LocalLensDatabase.defaultApplicationSupportURL()` stores local data under the user's Application Support directory in a `LocalLens` subdirectory. Database and cache paths are app-controlled and rebuildable from source files.

## Security and Privacy Deployment Notes

- Keep the app sandbox enabled.
- Keep user-selected file access read-only.
- Keep app-scope bookmarks enabled for persistent folder access.
- Keep provider credentials in Keychain.
- Validate remote-capable providers with explicit user opt-in and safe transport copy.
- Preserve source non-mutation guarantees in every release.
