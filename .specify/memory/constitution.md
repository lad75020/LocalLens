<!--
Sync Impact Report
Version change: Template baseline -> 1.0.0
Committed history reviewed: none; repository has no prior committed constitution. Current generated template was used as baseline.
Modified principles: Template principle 1 -> Explicit File-System Authority; Template principle 2 -> Local-First AI and Remote Inference Transparency; Template principle 3 -> Non-Destructive Media Processing; Template principle 4 -> Background Work and Responsive UI; Template principle 5 -> Testable Swift Architecture; added Privacy, Secrets, and Transport Guardrails; added Redacted Observability and Recoverability.
Added sections: Platform and Architecture Constraints; Development Workflow and Quality Gates.
Removed sections: none; generated placeholder sections were replaced with project-specific sections.
Templates requiring updates: ✅ .specify/templates/plan-template.md; ✅ .specify/templates/spec-template.md; ✅ .specify/templates/tasks-template.md.
Command templates: .specify/templates/commands is absent in this Spec Kit layout; extension command files live under .specify/extensions/*/commands and require no constitution-specific propagation.
Runtime guidance requiring updates: ✅ AGENTS.md.
Follow-up TODOs: none.
-->
# LocalLens Constitution

## Core Principles

### I. Explicit File-System Authority

LocalLens may request broad macOS file-system access only to fulfill user-directed
media indexing and search. Every feature that enumerates, reads, previews, exports,
or mutates files MUST document its authority boundary, user-visible trigger,
allowed roots, and failure behavior. Full-disk or all-filesystem access MUST be
paired with clear onboarding copy, revocation guidance, path redaction in ordinary
logs, and tests for denied, missing, moved, symlinked, external-drive, and
permission-restricted paths.

Rationale: this app can observe highly sensitive local files; broad access is a
privileged capability and cannot be treated as a normal implementation detail.

### II. Local-First AI and Remote Inference Transparency

Local AI inference MUST be the default for indexing, OCR, transcription,
classification, embeddings, summarization, and scene analysis. Any remote AI
provider, remote model endpoint, cloud API, or non-loopback inference service MUST
be opt-in per provider, visibly labeled before first use, and covered by a data
preview that states which file bytes, extracted text, transcripts, metadata,
filenames, prompts, or embeddings may leave the Mac. Non-loopback plaintext HTTP
or WebSocket inference MUST be blocked unless the user explicitly enables a
development-only exception for that exact host.

Rationale: the product promise depends on private media search, while still
allowing expert users to connect remote inference deliberately.

### III. Non-Destructive Media Processing

Indexing and search MUST NOT rename, move, delete, rewrite, transcode, or otherwise
modify source files unless a feature specification explicitly introduces that
capability and requires confirmation, undo or recovery, and dedicated tests. Any
future destructive operation MUST preserve originals by default, move deletions to
Trash where possible, and verify that later analysis stages have completed before
removing temporary or derived files.

Rationale: media libraries are personal records; search value must never create
silent data-loss risk.

### IV. Background Work and Responsive UI

Heavy file IO, recursive enumeration, image decoding, PDF parsing, Vision/Core ML
inference, MLX inference, audio transcription, video keyframe extraction,
thumbnailing, hashing, and database compaction MUST run outside the MainActor in
bounded, cancellable services or actors. SwiftUI view models MAY publish progress
and lightweight state on the MainActor, but MUST NOT own long-running indexing
loops. Every indexing stage MUST support cancellation checks before and after
expensive work and before any file-system side effect.

Rationale: a menu bar app must remain responsive even while processing large local
libraries.

### V. Testable Swift Architecture

Production code MUST use Swift 6 or newer, SwiftUI for primary UI, AppKit bridges
only where platform APIs require them, and dependency-injected services for file
access, persistence, inference, indexing, previews, and networking. Core behavior
MUST be testable without launching the full app. XCTest coverage is mandatory for
folder authorization, path handling, index queue transitions, extractor behavior,
search ranking, cancellation, and remote-inference guardrails.

Rationale: local AI and filesystem code has many edge cases; isolated services and
mandatory tests are required to keep implementation safe.

### VI. Privacy, Secrets, and Transport Guardrails

API keys, bearer tokens, model-provider credentials, and remote endpoint secrets
MUST be stored in Keychain, not UserDefaults or plain JSON. Remote transports MUST
use platform trust by default; self-signed or private certificates MUST be pinned
per host after explicit user approval. Diagnostic export MUST redact extracted
file contents, transcripts, prompts, credentials, and full paths by default. The
app MUST provide a privacy screen explaining local processing, remote-provider
exceptions, retained index data, and how to delete the local index.

Rationale: extracted media text and transcripts can be as sensitive as the original
files and must be protected as private user data.

### VII. Redacted Observability and Recoverability

Every long-running operation MUST emit structured progress, safe error categories,
retryability, and recovery actions. User-facing diagnostics MUST explain what
failed without exposing sensitive source content. Debug logs MAY include expanded
paths or raw provider responses only behind an explicit debug setting with a
sensitive-data warning and bounded retention. Indexing failures MUST be recoverable
through retry, ignore, reauthorize folder, or rebuild-index flows.

Rationale: users need confidence and control when local indexing fails, but logs
must not become a second copy of private files.

## Platform and Architecture Constraints

- **Platform**: macOS app targeting macOS 26.0+ unless a specification explicitly
  justifies broader support.
- **Language**: Swift 6 or newer with Swift concurrency and Sendable-aware service
  boundaries.
- **UI**: SwiftUI-first menu bar application; AppKit bridges are allowed for
  `NSOpenPanel`, Quick Look, Finder reveal, file coordination, and APIs without
  SwiftUI equivalents.
- **File access**: prefer user-selected folders and security-scoped bookmarks when
  sandboxed; if the app uses all-filesystem or Full Disk Access capabilities, each
  feature must still constrain enumeration and processing to user intent.
- **Persistence**: local metadata, thumbnails, embeddings, transcripts, and index
  state must live under Application Support or another explicit user-selected
  location.
- **Inference**: local providers must be available without a backend service;
  remote providers are adapters behind explicit privacy and transport gates.
- **Performance**: plans must define bounds for concurrency, memory use, thumbnail
  size, video sampling, transcript chunking, and index rebuild behavior.
- **Accessibility**: primary search, preview, reveal, pause, resume, and settings
  flows must be operable by keyboard and compatible with VoiceOver labels.

## Development Workflow and Quality Gates

- Specifications MUST include file-authority, privacy, inference, indexing,
  cancellation, and failure-mode requirements whenever a feature touches local
  files or AI providers.
- Implementation plans MUST pass a Constitution Check before research/design and
  again after design: file authority, local/remote inference, non-destructive
  behavior, background execution, testing, privacy/secrets, observability, and
  performance bounds.
- Tasks MUST include tests before implementation for security-sensitive and
  indexing-sensitive behavior. A task list that omits tests for file access,
  inference transport, cancellation, search ranking, or destructive operations is
  non-compliant.
- Build verification MUST include the relevant Xcode scheme or Swift Package tests
  before code is considered complete.
- Any remote AI provider addition MUST include Keychain storage, transport policy,
  redacted diagnostics, user-facing privacy copy, and tests that prove local-first
  defaults remain intact.
- Any source-file mutation capability MUST include confirmation UX, undo/recovery
  behavior, fixtures for failed operations, and regression tests before shipping.
- Manual QA for user-facing features MUST cover permission denial, external or
  missing drives, large folders, app restart, cancellation, and disabled network
  when local processing is expected.

## Governance

This constitution supersedes ad-hoc project preferences for LocalLens. Feature
specifications, implementation plans, task lists, code reviews, and release checks
MUST verify compliance with these principles. If a feature cannot comply, its plan
MUST document the violation, the user value that requires it, the safer alternative
that was rejected, and the mitigation that will be implemented.

Amendments require an explicit constitution change, an updated Sync Impact Report,
and propagation to affected Spec Kit templates or runtime guidance. Versioning
uses semantic versioning: MAJOR for principle removals or incompatible governance
changes, MINOR for new principles or materially expanded obligations, and PATCH
for clarifications that do not change required behavior.

Compliance review is required before `/speckit-plan`, before `/speckit-tasks`, and
before implementation is declared complete. Review evidence must include relevant
test results, build results, and any manual privacy or file-access QA required by
the feature.

**Version**: 1.0.0 | **Ratified**: 2026-06-15 | **Last Amended**: 2026-06-15
