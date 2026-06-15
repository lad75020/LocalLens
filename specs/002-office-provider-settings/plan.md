# Implementation Plan: Office Indexing and Provider Settings

**Branch**: `002-office-provider-settings` | **Date**: 2026-06-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-office-provider-settings/spec.md`

## Summary

Add provider-aware Settings controls and indexing support for Office documents. LocalLens will let users opt into `.pptx`, `.docx`, and `.xlsx` discovery/indexing only through Hermes Agent, with document-type-specific skill directives in prompts. Ollama and oMLX will gain explicit selected-model settings used for inference calls. Hermes Agent will gain profile discovery/selection from the provider-reported profile list, and Hermes-backed inference will use the selected profile. The approach extends existing Swift 6 macOS services: provider settings/persistence, Settings UI, discovery media typing, indexing orchestration, prompt templates, inference client request shaping, and privacy/failure diagnostics.

## Technical Context

**Language/Version**: Swift 6+, strict concurrency; macOS 26.0+ native SwiftUI/AppKit app.

**Primary Dependencies**: SwiftUI Settings window; AppKit only for existing window/file-access bridges; UniformTypeIdentifiers for Office extensions; existing SQLite repositories; existing `OpenAICompatibleClient`; Hermes Agent OpenAI-compatible API at `/v1` plus profile discovery endpoint; Ollama/oMLX OpenAI-compatible model and inference endpoints.

**Storage**: Local SQLite/Application Support storage through existing repositories. Extend provider/app settings and migrations for selected provider model IDs, Hermes profile selection/cache, Office indexing preferences, Office extraction records, and Office job states. Credentials remain in Keychain.

**Testing**: XCTest for model/profile selection persistence, provider request shaping, Office discovery gating, prompt directive safety, Hermes-only routing, stale selection handling, and indexing failure/retry paths. XCodeMCP is used for browsing/building/testing the open Xcode project.

**Target Platform**: macOS 26.0+ menu bar app.

**Project Type**: Native macOS SwiftUI/AppKit desktop/menu bar app.

**Performance Goals**: Settings provider/profile/model refresh completes or shows safe unavailable state within 5 seconds per provider. Office job progress appears within 2 seconds after a job starts. Office prompt payloads are bounded by existing prompt limits and chunking; large or unreadable Office files fail safely rather than exhausting memory.

**Constraints**: Source Office files remain read-only. Office indexing is Hermes Agent-only. Ollama and oMLX remain local loopback providers. Remote/custom providers never receive Office content for this feature. Prompts treat document contents as untrusted data and must include the literal required skill directive before document content. Settings remains keyboard/VoiceOver accessible and visually native with restrained Liquid Glass/material usage.

**Scale/Scope**: Adds three Office file types, two local-provider selected model settings, one Hermes profile selection flow, and one Hermes-backed Office extraction/indexing path integrated with existing queue/search/failure dashboards.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **File-system authority**: PASS — Reads user-selected watched folders and `.pptx`, `.docx`, `.xlsx` source files for indexing only; writes derived local index/job/settings/failure records; no source mutations.
- **Local-first AI**: PASS — Ollama/oMLX are local loopback providers with selected models; Hermes Agent is explicit and local API-server based, and Office indexing is available only when the user enables it.
- **Non-destructive media handling**: PASS — Office files are not renamed, moved, repaired, converted in place, deleted, or modified.
- **Responsive architecture**: PASS — Discovery, Office extraction requests, provider refreshes, and indexing jobs stay in cancellable background services/actors; Settings publishes lightweight state only.
- **Testable Swift design**: PASS — New behavior is planned through dependency-injected provider discovery, selection store, prompt builder, client adapter, discovery resolver, and indexing services with XCTest mocks.
- **Privacy/secrets/transport**: PASS — Credentials stay in Keychain; loopback HTTP only for local endpoints; diagnostics redact paths, prompts, raw provider bodies, and extracted content.
- **Observability/recovery**: PASS — Office job progress, provider readiness, stale model/profile state, retry/ignore/reauthorize/rebuild flows, and safe failure categories are included.
- **Performance bounds**: PASS — Model/profile refresh, prompt bounds, background Office extraction, large-file fail-safe behavior, and queue progress bounds are specified.

## Project Structure

### Documentation (this feature)

```text
specs/002-office-provider-settings/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── office-indexing-contract.md
│   ├── provider-selection-contract.md
│   └── hermes-agent-profile-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
LocalLens/
├── AppShell/
│   └── SettingsWindow.swift                 # Add Office indexing toggles, model pickers, profile picker, readiness copy
├── MediaDiscovery/
│   ├── MediaTypeResolver.swift              # Add Office document type resolution
│   └── MediaDiscoveryService.swift          # Gate Office discovery by settings/provider readiness
├── Indexing/
│   ├── IndexCoordinator.swift               # Add Office job dispatch/states
│   ├── IndexingPipelineRunner.swift         # Drain Office jobs with Hermes-only route
│   └── SearchableChunkBuilder.swift         # Build Office search chunks/snippets
├── Extractors/
│   └── OfficeDocumentExtractor.swift        # Hermes-backed Office extraction boundary
├── Inference/
│   ├── OpenAICompatibleClient.swift         # Selected model/profile-aware request helpers
│   ├── PromptTemplates.swift                # Office skill-directive prompts and injection guardrails
│   ├── ProviderRegistry.swift               # Provider defaults/capabilities
│   ├── ProviderSelectionService.swift       # Model/profile discovery and selection validation
│   └── ProviderTransportPolicy.swift        # Existing transport guardrails reused
├── Storage/
│   ├── Migrations/                          # Add migration for new settings/records
│   ├── Models/                              # Extend enums/entities for Office/provider selections
│   └── Repositories/                        # Persist preferences, model selections, profile cache
├── Diagnostics/
│   ├── FailureDashboardView.swift           # Existing safe recovery UI includes Office failures
│   └── RedactionPolicy.swift                # Existing redaction used for Office prompts/provider bodies
└── Support/
    └── DependencyContainer.swift            # Wire provider selection/Office extractor services

LocalLensTests/
├── AppShellTests/                           # Settings UI/model state tests
├── InferenceTests/                          # Prompt/directive/model/profile request tests
├── MediaDiscoveryTests/                     # Office type and gating discovery tests
├── IndexingTests/                           # Office queue/indexing/retry/cancel tests
├── PrivacySecurityTests/                    # Hermes-only routing and redaction tests
└── Fixtures/Office/                         # Small non-sensitive pptx/docx/xlsx fixtures or synthetic stubs
```

**Structure Decision**: Extend the existing native macOS module structure rather than adding a separate package. The feature crosses Settings, Inference, MediaDiscovery, Indexing, Storage, and Diagnostics, so each responsibility stays in its existing bounded folder. A new `OfficeDocumentExtractor` is the only new extraction boundary and is intentionally Hermes-only.

## Phase 0: Research

See [research.md](./research.md).

Resolved decisions:
- Office file type representation extends media/domain enums with `presentation`, `document`, and `spreadsheet` or an `officeDocument` type plus subtype, with the data model recommending explicit subtypes for filtering/prompting.
- Office discovery is settings-gated and Hermes-ready-gated, not globally enabled by UTType detection alone.
- Provider model selection stores one selected model per local provider and uses that selected value in all provider calls.
- Hermes profile selection uses provider-reported profiles and request metadata/header shaping, with fallback to a visible default only when available.
- Office prompt construction uses a stable instruction wrapper and treats document contents as untrusted data.

## Phase 1: Design & Contracts

See:
- [data-model.md](./data-model.md)
- [contracts/office-indexing-contract.md](./contracts/office-indexing-contract.md)
- [contracts/provider-selection-contract.md](./contracts/provider-selection-contract.md)
- [contracts/hermes-agent-profile-contract.md](./contracts/hermes-agent-profile-contract.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **File-system authority**: PASS — Data model and Office contract state read-only Office source access and derived local records only.
- **Local-first AI**: PASS — Provider-selection contract uses selected local Ollama/oMLX models; Office contract forbids non-Hermes routing.
- **Non-destructive media handling**: PASS — Quickstart includes byte-for-byte source mutation checks for Office fixtures.
- **Responsive architecture**: PASS — Contracts require async refresh/index flows and stale/unavailable states rather than blocking Settings or search.
- **Testable Swift design**: PASS — Contracts identify service boundaries and explicit tests for prompt directives, routing, selected models, selected profiles, and stale selections.
- **Privacy/secrets/transport**: PASS — Prompt/body redaction, loopback-only local providers, Keychain credentials, and no raw document content in diagnostics are maintained.
- **Observability/recovery**: PASS — Failure categories and recovery actions are part of the data model/contracts.
- **Performance bounds**: PASS — Quickstart and contracts include provider refresh timeouts, prompt bounds, large/corrupt/password-protected file behavior, and progress visibility.

## Complexity Tracking

No constitution violations or additional project complexity are introduced.
