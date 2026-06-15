# Office Fixtures

This directory intentionally contains only non-sensitive placeholders and validation notes for Office document indexing.

## Placeholder checksums

The automated tests synthesize tiny `.pptx`, `.docx`, and `.xlsx` placeholder files at runtime using deterministic UTF-8 content. They are not real user documents and contain no private data.

Expected sample payloads:

- `sample.pptx`: `PowerPoint quarterly roadmap placeholder`
- `sample.docx`: `Word project note placeholder`
- `sample.xlsx`: `Excel revenue table placeholder`

Runtime tests hash source bytes before and after indexing/cancel/retry/ignore/rebuild flows to prove LocalLens never mutates source Office files.

## Quickstart validation references

From `specs/002-office-provider-settings/quickstart.md`:

1. Enable the matching Office toggle in Settings.
2. Confirm Hermes Agent is enabled and a Hermes profile is selected.
3. Index a watched folder containing `.pptx`, `.docx`, and `.xlsx` placeholders.
4. Verify prompts include `Use the /pptx skill`, `Use the /docx skill`, or `Use the /xlsx skill` outside the untrusted data section.
5. Verify Office content never routes to Ollama, oMLX, or custom providers.
6. Verify diagnostics omit raw Office text, prompts, provider bodies, credentials, and full paths.
