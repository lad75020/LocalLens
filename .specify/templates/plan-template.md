# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift 6+ or NEEDS CLARIFICATION

**Primary Dependencies**: SwiftUI, AppKit bridges as needed, Vision, AVFoundation, PDFKit, local AI/inference libraries, persistence layer, or NEEDS CLARIFICATION

**Storage**: Local Application Support database/files, security-scoped bookmarks, model/index storage, or NEEDS CLARIFICATION

**Testing**: XCTest plus focused fixture/manual QA for file access, inference, indexing, and privacy behavior

**Target Platform**: macOS 26.0+ menu bar app unless feature explicitly broadens support

**Project Type**: native macOS SwiftUI/AppKit desktop/menu bar app

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **File-system authority**: PASS only if the plan states which roots/files are read or changed, how broad filesystem access is justified, how denied/moved/external paths behave, and whether operations are non-destructive.
- **Local-first AI**: PASS only if local inference remains the default and any remote provider is opt-in, labeled, transport-guarded, and covered by privacy copy.
- **Non-destructive media handling**: PASS only if indexing/search do not mutate source files, or any mutation includes confirmation, recovery, and dedicated tests.
- **Responsive architecture**: PASS only if recursive scanning, IO, decoding, OCR, transcription, embeddings, video sampling, and database work run in cancellable background services/actors outside the MainActor.
- **Testable Swift design**: PASS only if services are dependency-injected and XCTest coverage is planned for file access, indexing queues, extractors, search ranking, cancellation, and guardrails.
- **Privacy/secrets/transport**: PASS only if credentials use Keychain, remote TLS/self-signed behavior is specified, diagnostics are redacted, and local index retention/deletion is documented.
- **Observability/recovery**: PASS only if progress, failure categories, retry/ignore/reauthorize/rebuild actions, and safe diagnostic export are specified.
- **Performance bounds**: PASS only if concurrency, memory, thumbnail size, video sampling, chunking, and index rebuild bounds are documented.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
LocalLens/
├── AppShell/              # MenuBarExtra, settings, onboarding, app lifecycle
├── FolderAccess/          # NSOpenPanel and security-scoped bookmark services
├── MediaDiscovery/        # UTType detection, recursive scanning, file identity
├── Indexing/              # Queue actors, orchestration, cancellation, progress
├── Extractors/            # OCR, PDF, audio, video, thumbnail, scene services
├── Embeddings/            # Local embedding providers and chunking
├── Search/                # Lexical/semantic search, ranking, snippets
├── PreviewActions/        # Quick Look, Finder reveal, open/copy actions
├── Storage/               # Database, migrations, thumbnail/index storage
├── Diagnostics/           # Redacted logs, failure reports, privacy checks
└── Resources/

LocalLensTests/
├── FolderAccessTests/
├── MediaDiscoveryTests/
├── IndexingTests/
├── ExtractorTests/
├── SearchTests/
├── PrivacySecurityTests/
└── Fixtures/
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
