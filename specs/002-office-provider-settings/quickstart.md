# Quickstart: Office Indexing and Provider Settings

## Prerequisites

- macOS 26.0+.
- Xcode 26.x with Swift 6+.
- LocalLens repository at `/Volumes/WDBlack4TB/Code/LocalLens`.
- LocalLens Xcode project open in Xcode; XCodeMCP tab: `windowtab4`.
- Optional local providers:
  - Ollama at `http://localhost:11434/v1`.
  - oMLX at `http://localhost:17998/v1`.
  - Hermes Agent API server at `http://localhost:8642/v1`.

Provider unavailability must not prevent LocalLens from launching or indexing existing supported non-Office media.

## Planned Settings Smoke Flow

1. Launch LocalLens.
2. Open Settings.
3. Open AI Providers.
4. Refresh providers.
5. Verify Ollama row shows a model picker when models are reported.
6. Select an Ollama model and close/reopen Settings; verify it remains selected.
7. Verify oMLX row shows a model picker when models are reported.
8. Select an oMLX model and close/reopen Settings; verify it remains selected.
9. Verify Hermes Agent row shows a profile picker populated from provider-reported profiles.
10. Select a Hermes profile and close/reopen Settings; verify it remains selected.
11. Verify stale/unavailable model/profile selections show warnings and block new provider-backed work.

## Planned Office Indexing Smoke Flow

1. Prepare a folder containing small non-sensitive fixtures:
   - `sample.pptx`
   - `sample.docx`
   - `sample.xlsx`
   - one existing supported image/PDF/audio/video fixture.
2. Record checksums or byte counts for each Office file.
3. In Settings, enable Office indexing for `.pptx`, `.docx`, and `.xlsx`.
4. Ensure Hermes Agent provider is enabled and a valid Hermes profile is selected.
5. Add or reindex the watched folder.
6. Verify `.pptx`, `.docx`, and `.xlsx` jobs are queued only for Hermes Agent.
7. Verify generated prompts include the matching literal directives:
   - `Use the /pptx skill`
   - `Use the /docx skill`
   - `Use the /xlsx skill`
8. Verify Ollama, oMLX, and custom remote providers receive no Office document content.
9. Verify search results for indexed Office documents show filename, document type, folder context, match reason, and bounded safe snippet/summary.
10. Re-check source Office file checksums or byte counts; they must be unchanged.

## Failure/Recovery Smoke Flow

1. Disable Hermes Agent and add a folder containing Office files.
2. Verify Office jobs do not start and Settings explains Hermes Agent is required.
3. Select a Hermes profile, then simulate the API no longer reporting that profile.
4. Verify Settings marks the profile stale and Office jobs do not start until a valid profile is selected.
5. Use a corrupt or password-protected Office fixture.
6. Verify failure dashboard shows a safe category and retry/ignore recovery without exposing full path or raw document content.
7. Cancel an Office indexing job.
8. Verify the job becomes cancelled and can be retried without modifying the source file.

## Automated Validation Targets

Use XCTest and XCodeMCP for verification.

### Unit tests

- `MediaTypeResolver` recognizes `.pptx`, `.docx`, and `.xlsx` when Office indexing is enabled.
- `MediaDiscoveryService` skips Office files when the matching toggle is disabled.
- Office files are not queued when Hermes Agent is unavailable or profile selection is stale.
- `PromptTemplates` emits the required skill directive for each Office type.
- Prompt-injection fixture text remains in an untrusted data section.
- `OpenAICompatibleClient` or Hermes adapter sends selected Hermes profile control while keeping model as the Hermes compatibility model.
- Ollama inference request uses selected Ollama model.
- oMLX inference request uses selected oMLX model.
- Stale selected model/profile blocks new provider-backed work.
- Redacted diagnostics omit raw Office content, full prompts, credentials, and raw provider bodies.

### UI tests

- Settings AI Providers tab exposes accessible model pickers for Ollama/oMLX.
- Settings AI Providers tab exposes accessible Hermes profile picker.
- Settings Office indexing toggles are keyboard accessible and persist after app restart.
- Unavailable/stale state copy is visible and understandable.

### Privacy/security tests

- Office source fixture bytes are unchanged after indexing, failure, cancellation, retry, ignore, and rebuild.
- Non-Hermes providers are never called for Office indexing.
- Remote/custom provider automatic indexing remains disabled for Office files.
- Diagnostics export contains safe counts/categories only.

## Build/Test Verification

Regenerate project if project.yml changes:

```bash
xcodegen generate
```

Preferred verification through XCodeMCP:

```text
XCodeMCP BuildProject(tabIdentifier: windowtab4)
XCodeMCP RunSomeTests(tabIdentifier: windowtab4, tests: [new Office/provider tests])
XCodeMCP RunAllTests(tabIdentifier: windowtab4)
```

CLI fallback if XCodeMCP is unavailable:

```bash
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build
xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' test
```

Do not mark implementation complete until the app builds and relevant unit/UI/privacy tests pass.

## Implementation Verification Record

Recorded during `/speckit-implement` resume on 2026-06-16 01:50:52 CEST.

- XCodeMCP `BuildProject(tabIdentifier: windowtab4)`: PASS — `The project built successfully.` Log: `/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/ActionArtifacts/default/BuildProject/BuildProject-Log-20260616-014954.txt`.
- XCodeMCP `RunAllTests(tabIdentifier: windowtab4)`: PASS — 88 tests total, 87 passed, 0 failed, 0 skipped, 0 expected failures, 1 not run (`LocalLensUITestBase`, no-result base class). Console log: `/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/ActionArtifacts/default/RunAllTests/test-console-log-2026-06-16T01-49-57+02-00.txt`; summary: `/var/folders/gq/fj68kcfn2t1fb21qqrt6b44h0000gn/T/ActionArtifacts/default/RunAllTests/74A301B9-DC36-476B-8677-209B1D04CB98.txt`.
