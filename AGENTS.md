<!-- SPECKIT START -->
For Spec Kit work, read `.specify/memory/constitution.md` before writing specs,
plans, tasks, or implementation code.

LocalLens is a native macOS Swift app with broad local file visibility and local or remote AI inference adapters. Treat filesystem access, extracted media text,
transcripts, embeddings, model prompts, remote providers, logs, and diagnostics
as sensitive by default.

Implementation guidance:
- Use Swift 6+, SwiftUI-first app structure, AppKit bridges only when needed.
- Keep local AI inference as the default; remote inference must be explicit,
  opt-in, transport-guarded, and redacted in diagnostics.
- Do not mutate user source files unless a spec explicitly adds that capability
  with confirmation, recovery, and tests.
- Keep heavy IO/media/inference/indexing work outside the MainActor in bounded,
  cancellable services or actors.
- Add XCTest coverage for file authority, indexing, inference guardrails,
  cancellation, search ranking, and failure recovery.
- Current project generation uses `project.yml` + `xcodegen generate`; do not hand-edit
  generated `LocalLens.xcodeproj` settings that belong in `project.yml`.
- Build/test verification fallback when XCodeMCP cannot target LocalLens:
  `xcodebuild -project LocalLens.xcodeproj -scheme LocalLens -destination 'platform=macOS' build`
  and `... test`.
- Local provider defaults: oMLX `http://localhost:17998/v1`, Ollama
  `http://localhost:11434/v1`, Hermes Agent `http://localhost:8642/v1`.
  Hermes Agent must remain disabled for automatic bulk indexing unless the user opts in.
- Redaction rules: diagnostic export must hash full paths and omit credentials,
  prompts, raw provider bodies, extracted text, transcripts, thumbnails, and file bytes.
- Source-media constraint: source files are read-only; all generated index/cache data
  must stay under app-controlled Application Support paths.
<!-- SPECKIT END -->
