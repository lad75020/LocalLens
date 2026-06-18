# Developer Guide

## Development Environment Setup

### Prerequisites

- macOS 26.0 or later for the target platform.
- Xcode that supports Swift 6 and macOS 26 SDKs.
- Swift 6 with strict concurrency support.
- Optional: XcodeGen-compatible tooling if you regenerate `LocalLens.xcodeproj` from `project.yml`.
- Optional local providers for provider-backed manual QA:
  - oMLX OpenAI-compatible endpoint at `http://localhost:17998/v1`
  - Ollama OpenAI-compatible endpoint at `http://localhost:11434/v1`
  - Hermes Agent endpoint at `http://localhost:8642/v1`

### First-Time Setup

1. Clone or open the repository:

   ```bash
   cd /Volumes/WDBlack4TB/Code/LocalLens
   open LocalLens.xcodeproj
   ```

2. Select the shared `LocalLens` scheme.

3. Build the app from Xcode, or from the command line:

   ```bash
   xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
   ```

4. Run tests from Xcode, or from the command line:

   ```bash
   xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
   ```

5. For UI tests that need a clean state, pass the app argument `--ui-testing-fresh-state`. `LocalLensApp` removes the app support directory when that argument is present.

### Updating Your Environment

After pulling changes:

```bash
cd /Volumes/WDBlack4TB/Code/LocalLens
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
```

If the Xcode project is regenerated from `project.yml`, confirm the shared scheme still builds `LocalLens`, `LocalLensTests`, and `LocalLensUITests`.

## Project Structure

```text
LocalLens/
  AppShell/          # SwiftUI app shell, settings, search popover, commands
  DesignSystem/      # Local UI theme and reusable UI components
  Diagnostics/       # Redaction, privacy audit, diagnostic export, failure UI
  Extractors/        # Media extraction and thumbnail services
  FolderAccess/      # Security scoped bookmarks and watched folder state
  Indexing/          # Background queue, coordinator, chunks, progress, cancellation
  Inference/         # Provider endpoints, model/profile selection, readiness, prompts
  MediaDiscovery/    # Recursive file discovery and media type resolution
  PreviewActions/    # Quick Look, Finder reveal, open, copy actions
  Resources/         # Info.plist, entitlements, asset catalogs
  Search/            # Search service, ranker, vector search, snippets, view model
  Storage/           # SQLite database, migrations, domain models, repositories
  Support/           # BuildConfiguration and DependencyContainer
LocalLensTests/      # XCTest coverage by feature area
LocalLensUITests/    # XCUITest coverage for onboarding, settings, search
specs/               # Speckit feature specs, contracts, quickstarts, tasks
.sdd/docs/           # Generated application documentation
```

Start with these files when learning the codebase:

- `LocalLens/LocalLensApp.swift` for the app entry point.
- `LocalLens/Support/DependencyContainer.swift` for service composition.
- `LocalLens/Storage/Migrations/MigrationV1.swift` for persistence structure.
- `LocalLens/Indexing/IndexingPipelineRunner.swift` and `LocalLens/Indexing/IndexCoordinator.swift` for indexing.
- `LocalLens/Search/SearchService.swift` for query execution.
- `LocalLens/Inference/ProviderRoutingService.swift` for provider route decisions.
- `LocalLens/AppShell/SettingsWindow.swift` for provider and indexing settings UI.

## Coding Conventions

### Naming

- Types use `PascalCase`: `LocalLensDatabase`, `ProviderRoutingService`, `SearchResultViewModel`.
- Methods, properties, and local values use Swift `camelCase`: `readinessForPreferredDescription`, `selectedModelID`.
- Source files are usually named after the primary type they contain.
- Test files are grouped by feature and named with the tested behavior area, such as `AIProviderRoutingPreferenceTests.swift`.

### File Organization

The app is organized by architectural layer and feature area. UI lives in `AppShell`, persistence in `Storage`, indexing in `Indexing`, inference provider logic in `Inference`, search in `Search`, and macOS file/action integrations in `FolderAccess` and `PreviewActions`.

### Concurrency

- `DependencyContainer` is `@MainActor` and composes UI-observed state.
- Long-running indexing runs in actors such as `IndexingPipelineRunner` and `IndexQueueActor`.
- Database access is actor-isolated in `LocalLensDatabase`.
- Services that can cross concurrency boundaries use `Sendable` where appropriate.

### Error Handling

- Storage throws typed `LocalLensDatabaseError` values for open, execution, corruption, and closed-handle cases.
- Extraction and indexing failures are mapped to safe failure categories and retryability.
- Provider routing returns explicit allowed or blocked route decisions instead of silently falling back.
- User-visible diagnostics must be safe and redacted.

### Privacy and Security Conventions

- Source files must remain unchanged. Tests in `PrivacySecurityTests` enforce this property.
- Provider credentials belong in `ProviderCredentialStore` and the Keychain, not in plaintext docs or logs.
- Diagnostics must not include raw prompts, raw provider bodies, full paths, credentials, or full extracted/generated content by default.
- Remote-capable providers must pass transport and readiness checks before content leaves the Mac.

### Formatting and Tooling

No separate formatter configuration file was found in this evidence pass. Follow idiomatic Swift formatting and keep generated documentation ASCII-only when using the structured doc skills.

## Testing

### Test Structure

- `LocalLensTests/StorageTests`: SQLite schema and repository behavior.
- `LocalLensTests/FolderAccessTests`: bookmarks and watched folder behavior.
- `LocalLensTests/MediaDiscoveryTests`: recursive discovery and Office policy.
- `LocalLensTests/ExtractorTests`: image, PDF, audio, video, and thumbnail extraction.
- `LocalLensTests/IndexingTests`: pipeline, queue, cancellation, progress, generated content, and Office indexing.
- `LocalLensTests/InferenceTests`: provider transport, model/profile discovery, routing, readiness, prompt templates.
- `LocalLensTests/SearchTests`: FTS, semantic vector search, ranking, snippets, performance.
- `LocalLensTests/DiagnosticsTests` and `PrivacySecurityTests`: redaction, privacy defaults, source mutation, storage maintenance.
- `LocalLensUITests`: onboarding, settings, provider controls, Hermes profile selection, search popover behavior.

### Running Tests

```bash
# Build the app and test bundles
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build

# Run all unit and UI tests declared by the shared scheme
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test

# Run a focused unit test class
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' -only-testing:LocalLensTests/AIProviderRoutingPreferenceTests test

# Run a focused UI test class
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' -only-testing:LocalLensUITests/SettingsUITests test
```

The shared scheme has coverage enabled in `project.yml` and the Xcode scheme.

## Adding New Features

### Development Workflow

1. Update or add the relevant `specs/<feature>/` artifacts before implementation when using the Speckit workflow.
2. Identify the affected layer: UI, discovery, indexing, inference, storage, search, diagnostics, or tests.
3. Add or update domain models and migrations before repository code.
4. Extend services through dependency injection rather than introducing global state.
5. Add focused tests in the matching `LocalLensTests` directory and UI tests when behavior is visible in Settings or the popover.
6. Run build and relevant tests before committing.
7. If source structure changes significantly, refresh the codebase-memory index after verification.

### Example: Adding a Provider-Backed Indexing Capability

1. Add or update settings models and repository support in `Storage`.
2. Add route rules in `Inference/ProviderRoutingService.swift` and readiness rules in `ProviderReadinessService.swift`.
3. Add prompt construction in `Inference/PromptTemplates.swift`.
4. Integrate the stage in `Indexing/IndexCoordinator.swift` or `IndexingPipelineRunner.swift`.
5. Persist generated text in `generated_content_records` and searchable chunks.
6. Add tests for route selection, readiness failure, storage, FTS searchability, diagnostics redaction, and source non-mutation.
7. Update `SettingsWindow.swift` only after the service and storage behavior are testable.

### File Checklist

- [ ] `Storage/Models/LocalLensModels.swift`: Domain model changes.
- [ ] `Storage/Migrations/MigrationV1.swift`: Additive schema changes.
- [ ] `Storage/Repositories/RepositoryProtocols.swift`: New repository protocol surface.
- [ ] `Storage/Repositories/SQLiteRepositories.swift`: SQLite implementation.
- [ ] `Inference/*`: Provider selection, routing, readiness, credentials, prompts.
- [ ] `Indexing/*`: Queue/coordinator integration.
- [ ] `Search/*`: Query/ranking/snippet changes if search behavior changes.
- [ ] `Diagnostics/*`: Redacted operational reporting.
- [ ] `LocalLensTests/*`: Focused behavior tests.
- [ ] `LocalLensUITests/*`: UI-visible behavior tests.

## Common Pitfalls

- Do not treat provider rows as permission to transmit content. Readiness, transport, credentials, selected profile/model, and privacy gates still apply.
- Do not use fallback providers for image/PDF enrichment when the selected provider is unavailable.
- Do not route Office content to Ollama, oMLX, or custom remote providers.
- Do not create audio/video provider prompts for new indexing work.
- Do not persist raw prompt bodies, credentials, or unbounded generated text in diagnostics.
- Do not mutate source files in indexing, preview, search, diagnostics, retry, rebuild, or cleanup flows.
