# Contract: Indexing Pipeline

## Pipeline Stages

1. `discoverFolder`: enumerate supported media in a watched folder.
2. `identifyAsset`: resolve UTType, file signature, size, dates, and file identity.
3. `thumbnail`: generate bounded thumbnail/key preview.
4. `extractPrimaryMetadata`: dimensions, duration, page count, media metadata.
5. `extractTextualContent`: OCR, PDF text, transcript, frame OCR.
6. `extractVisualMetadata`: Vision labels or provider-generated labels/scene summaries.
7. `chunkSearchContent`: create bounded searchable chunks with page/timestamp context.
8. `embedChunks`: generate embeddings through local provider when available.
9. `commitCompleteState`: mark asset complete/partial only after durable writes.

## State Machine

```text
discovered -> queued -> indexing -> complete
                         |       -> partial
                         |       -> failed
                         |       -> cancelled
complete -> stale -> queued
failed   -> queued | ignored
missing  -> queued when rediscovered
```

Rules:
- `cancelled` and `failed` records must not be presented as complete.
- A partial record must include stage-level explanation.
- Queue state must survive quit/relaunch.
- Pause prevents new jobs from starting but allows a running stage to checkpoint or cancel safely.

## Cancellable Service Protocol

```swift
protocol IndexStageService: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func run(
        input: Input,
        context: IndexStageContext
    ) async throws -> Output
}

struct IndexStageContext: Sendable {
    let assetID: UUID
    let cancellation: IndexCancellation
    let progress: ProgressSink
    let authorization: FolderAuthorizationToken
}
```

## Concurrency Bounds

- Discovery: bounded concurrent directory traversal; skip unsupported packages/hidden paths according to settings.
- OCR/PDF: bounded to avoid memory spikes on huge images/PDFs.
- Audio/video: one or few heavyweight jobs at a time by default.
- Provider requests: separate per-provider concurrency limit and timeout.
- Database writes: serialized by storage actor/repository transaction boundary.

## Failure Categories

- `permissionDenied`
- `staleBookmark`
- `missingFolder`
- `missingFile`
- `unsupportedMedia`
- `corruptedMedia`
- `passwordProtectedPDF`
- `modelUnavailable`
- `providerTimeout`
- `transportBlocked`
- `cancelled`
- `storageFull`
- `databaseError`
- `unknownRedacted`

## Non-Destructive Guarantee

The pipeline may read source bytes and write derived app-private data only. It must not:
- write source files
- modify source file metadata
- rename/move/delete source files
- transcode source media in place
- create sibling sidecar files next to source media without a future explicit spec

## Progress Snapshot

```swift
struct IndexProgressSnapshot: Equatable, Sendable {
    var isRunning: Bool
    var isPaused: Bool
    var queuedCount: Int
    var runningCount: Int
    var completedCount: Int
    var failedCount: Int
    var cancelledCount: Int
    var currentSafeLabel: String?
    var lastIndexedAt: Date?
}
```

The UI may display `currentSafeLabel` such as file name or redacted path context, but diagnostics must redact full paths by default.
