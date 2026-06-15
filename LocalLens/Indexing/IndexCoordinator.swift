import Foundation

public actor IndexCoordinator {
    public init() {}

    @discardableResult
    public func indexImageOrPDF(
        asset originalAsset: MediaAsset,
        sourceURL: URL,
        storage: StorageRepositories,
        cachePaths: CachePaths,
        thumbnailService: ThumbnailService = ThumbnailService(),
        imageExtractor: ImageExtractor = ImageExtractor(),
        pdfExtractor: PDFExtractor = PDFExtractor(),
        chunkBuilder: SearchableChunkBuilder = SearchableChunkBuilder(),
        embeddingStageService: EmbeddingStageService = EmbeddingStageService(),
        providers: [ProviderSetting] = [],
        cancellation: IndexCancellation = IndexCancellation()
    ) async -> ImagePDFIndexResult {
        var asset = originalAsset
        var partialFailures: [FailureCategory] = []
        var thumbnailURL: URL?

        do {
            try cancellation.checkCancellation()
            asset.indexState = .indexing
            asset.updatedAt = Date()
            try await storage.assets.save(asset)

            do {
                let thumbnail = try await thumbnailService.generateThumbnail(
                    for: sourceURL,
                    assetID: asset.id,
                    mediaType: asset.mediaType,
                    cachePaths: cachePaths
                )
                thumbnailURL = thumbnail.thumbnailURL
                asset.thumbnailState = .complete
                try await storage.extractionRecords.save(record(assetID: asset.id, stage: .thumbnail, status: .complete, summary: "Bounded thumbnail generated"))
            } catch {
                let failure = ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
                asset.thumbnailState = .failed
                partialFailures.append(failure.category)
                try await storage.extractionRecords.save(record(assetID: asset.id, stage: .thumbnail, status: .failed, summary: failure.localizedDescription, error: failure.category))
            }

            try cancellation.checkCancellation()

            var imageResult: ImageExtractionResult?
            var pdfResult: PDFExtractionResult?
            var recordIDs: [ExtractionStage: UUID] = [:]

            switch asset.mediaType {
            case .image:
                let result = try await imageExtractor.extract(from: sourceURL)
                imageResult = result
                asset.dimensions = result.dimensions
                let metadata = try await saveRecord(storage, assetID: asset.id, stage: .metadata, status: .complete, summary: "Image dimensions \(result.dimensions)")
                recordIDs[.metadata] = metadata
                let ocr = try await saveRecord(storage, assetID: asset.id, stage: .imageOCR, status: .complete, summary: "\(result.recognizedText.count) OCR observations")
                recordIDs[.imageOCR] = ocr
                let labels = try await saveRecord(storage, assetID: asset.id, stage: .imageLabels, status: .complete, summary: "\(result.visualLabels.count) visual labels")
                recordIDs[.imageLabels] = labels
            case .pdf:
                let result = try await pdfExtractor.extract(from: sourceURL)
                pdfResult = result
                asset.pageCount = result.pageCount
                let metadata = try await saveRecord(storage, assetID: asset.id, stage: .metadata, status: .complete, summary: "PDF page count \(result.pageCount)")
                recordIDs[.metadata] = metadata
                let pdfTextState: IndexState = result.text.isEmpty ? .partial : .complete
                let pdfText = try await saveRecord(storage, assetID: asset.id, stage: .pdfText, status: pdfTextState, summary: "\(result.pages.count) PDF pages processed", error: result.failureCategory)
                recordIDs[.pdfText] = pdfText
                if result.partialFailureCount > 0 || result.failureCategory != nil {
                    partialFailures.append(result.failureCategory ?? .unknownRedacted)
                }
            case .audio, .video:
                throw ExtractionFailure.failed(category: .unsupportedMedia, retryability: .ignore, safeMessage: "Only image and PDF assets are handled by this indexing stage.")
            }

            try cancellation.checkCancellation()
            var chunks = chunkBuilder.chunks(for: asset, imageResult: imageResult, pdfResult: pdfResult, extractionRecordIDs: recordIDs)
            let embeddingResult = await embeddingStageService.embed(chunks: chunks, providers: providers)
            chunks = embeddingResult.chunks
            if let failure = embeddingResult.failureCategory, embeddingResult.state == .partial {
                partialFailures.append(failure)
            }
            for chunk in chunks {
                try await storage.chunks.save(chunk)
            }
            try await storage.extractionRecords.save(record(assetID: asset.id, stage: .embeddings, providerID: embeddingResult.providerID, status: embeddingResult.state, summary: embeddingResult.providerID == nil ? "No automatic local embedding provider configured" : "Embedding stage completed", error: embeddingResult.failureCategory))

            let finalState: IndexState = partialFailures.isEmpty ? .complete : .partial
            asset.indexState = finalState
            asset.lastIndexedAt = Date()
            asset.updatedAt = Date()
            try await storage.assets.save(asset)
            return ImagePDFIndexResult(assetID: asset.id, state: finalState, thumbnailURL: thumbnailURL, chunkCount: chunks.count, failureCategory: partialFailures.first)
        } catch is CancellationError {
            asset.indexState = .cancelled
            asset.lastIndexedAt = nil
            asset.updatedAt = Date()
            try? await storage.assets.save(asset)
            try? await storage.failures.save(IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: asset.watchedFolderID, stage: "imagePDF", category: .cancelled, retryability: .retry, safeMessage: "Indexing was cancelled.", rawDebugReference: nil, createdAt: Date(), resolvedAt: nil))
            return ImagePDFIndexResult(assetID: asset.id, state: .cancelled, thumbnailURL: thumbnailURL, chunkCount: 0, failureCategory: .cancelled)
        } catch {
            let failure = ExtractionFailure.map(error, defaultCategory: .unknownRedacted)
            asset.indexState = .failed
            asset.updatedAt = Date()
            try? await storage.assets.save(asset)
            try? await storage.failures.save(IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: asset.watchedFolderID, stage: "imagePDF", category: failure.category, retryability: failure.retryability, safeMessage: failure.localizedDescription, rawDebugReference: nil, createdAt: Date(), resolvedAt: nil))
            return ImagePDFIndexResult(assetID: asset.id, state: .failed, thumbnailURL: thumbnailURL, chunkCount: 0, failureCategory: failure.category)
        }
    }

    @discardableResult
    public func indexAudioVideo(
        asset originalAsset: MediaAsset,
        sourceURL: URL,
        storage: StorageRepositories,
        audioExtractor: AudioTranscriptExtractor = AudioTranscriptExtractor(),
        videoExtractor: VideoSceneExtractor = VideoSceneExtractor(),
        chunkBuilder: SearchableChunkBuilder = SearchableChunkBuilder(),
        embeddingStageService: EmbeddingStageService = EmbeddingStageService(),
        providers: [ProviderSetting] = [],
        cancellation: IndexCancellation = IndexCancellation()
    ) async -> AudioVideoIndexResult {
        var asset = originalAsset
        var partialFailures: [FailureCategory] = []

        do {
            try cancellation.checkCancellation()
            asset.indexState = .indexing
            asset.updatedAt = Date()
            try await storage.assets.save(asset)

            var audioResult: AudioExtractionResult?
            var videoResult: VideoSceneExtractionResult?
            var recordIDs: [ExtractionStage: UUID] = [:]

            switch asset.mediaType {
            case .audio:
                let result = try await audioExtractor.extract(from: sourceURL)
                audioResult = result
                asset.durationSeconds = result.durationSeconds
                recordIDs[.metadata] = try await saveRecord(storage, assetID: asset.id, stage: .metadata, status: .complete, summary: "Audio duration \(Self.durationSummary(result.durationSeconds))")
                let transcriptState: IndexState = result.failureCategory == nil ? .complete : .partial
                recordIDs[.audioTranscript] = try await saveRecord(storage, assetID: asset.id, stage: .audioTranscript, status: transcriptState, summary: result.transcriptSegments.isEmpty ? "No local transcript chunks available" : "\(result.transcriptSegments.count) transcript chunks", error: result.failureCategory, timestampStart: result.transcriptSegments.first?.timestampStart, timestampEnd: result.transcriptSegments.last?.timestampEnd, confidence: result.transcriptSegments.compactMap(\.confidence).max())
                if let failure = result.failureCategory { partialFailures.append(failure) }

            case .video:
                let result = try await videoExtractor.extract(from: sourceURL)
                videoResult = result
                asset.durationSeconds = result.durationSeconds
                asset.thumbnailState = result.keyframes.isEmpty ? .partial : .complete
                recordIDs[.metadata] = try await saveRecord(storage, assetID: asset.id, stage: .metadata, status: .complete, summary: "Video duration \(Self.durationSummary(result.durationSeconds))")
                recordIDs[.videoKeyframe] = try await saveRecord(storage, assetID: asset.id, stage: .videoKeyframe, status: result.keyframes.isEmpty ? .partial : .complete, summary: "\(result.keyframes.count) representative keyframes from \(result.sampledFrameCount) bounded samples", error: result.keyframes.isEmpty ? .corruptedMedia : nil, timestampStart: result.keyframes.first?.timestamp, timestampEnd: result.keyframes.last?.timestamp)
                recordIDs[.sceneLabels] = try await saveRecord(storage, assetID: asset.id, stage: .sceneLabels, status: result.keyframes.isEmpty ? .partial : .complete, summary: "\(result.keyframes.flatMap(\.visualLabels).count) sampled scene labels", error: result.keyframes.isEmpty ? .corruptedMedia : nil, timestampStart: result.keyframes.first?.timestamp, timestampEnd: result.keyframes.last?.timestamp, confidence: result.keyframes.flatMap(\.visualLabels).map(\.confidence).max())
                let transcriptState: IndexState = result.failureCategory == nil ? .complete : .partial
                recordIDs[.videoTranscript] = try await saveRecord(storage, assetID: asset.id, stage: .videoTranscript, status: transcriptState, summary: result.transcriptSegments.isEmpty ? "No local audio-track transcript chunks available" : "\(result.transcriptSegments.count) audio-track transcript chunks", error: result.failureCategory, timestampStart: result.transcriptSegments.first?.timestampStart, timestampEnd: result.transcriptSegments.last?.timestampEnd, confidence: result.transcriptSegments.compactMap(\.confidence).max())
                if let failure = result.failureCategory { partialFailures.append(failure) }

            case .image, .pdf:
                throw ExtractionFailure.failed(category: .unsupportedMedia, retryability: .ignore, safeMessage: "Only audio and video assets are handled by this indexing stage.")
            }

            try cancellation.checkCancellation()
            var chunks = chunkBuilder.chunks(for: asset, imageResult: nil, pdfResult: nil, audioResult: audioResult, videoResult: videoResult, extractionRecordIDs: recordIDs)
            let embeddingResult = await embeddingStageService.embed(chunks: chunks, providers: providers)
            chunks = embeddingResult.chunks
            if let failure = embeddingResult.failureCategory, embeddingResult.state == .partial { partialFailures.append(failure) }
            for chunk in chunks { try await storage.chunks.save(chunk) }
            try await storage.extractionRecords.save(record(assetID: asset.id, stage: .embeddings, providerID: embeddingResult.providerID, status: embeddingResult.state, summary: embeddingResult.providerID == nil ? "No automatic local embedding provider configured" : "Embedding stage completed", error: embeddingResult.failureCategory))

            let finalState: IndexState = partialFailures.isEmpty ? .complete : .partial
            asset.indexState = finalState
            asset.lastIndexedAt = Date()
            asset.updatedAt = Date()
            try await storage.assets.save(asset)
            return AudioVideoIndexResult(assetID: asset.id, state: finalState, chunkCount: chunks.count, sampledFrameCount: videoResult?.sampledFrameCount ?? 0, failureCategory: partialFailures.first)
        } catch is CancellationError {
            asset.indexState = .cancelled
            asset.lastIndexedAt = nil
            asset.updatedAt = Date()
            try? await storage.assets.save(asset)
            try? await storage.failures.save(IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: asset.watchedFolderID, stage: "audioVideo", category: .cancelled, retryability: .retry, safeMessage: "Indexing was cancelled.", rawDebugReference: nil, createdAt: Date(), resolvedAt: nil))
            return AudioVideoIndexResult(assetID: asset.id, state: .cancelled, chunkCount: 0, sampledFrameCount: 0, failureCategory: .cancelled)
        } catch {
            let failure = ExtractionFailure.map(error, defaultCategory: .unknownRedacted)
            asset.indexState = .failed
            asset.updatedAt = Date()
            try? await storage.assets.save(asset)
            try? await storage.failures.save(IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: asset.watchedFolderID, stage: "audioVideo", category: failure.category, retryability: failure.retryability, safeMessage: failure.localizedDescription, rawDebugReference: nil, createdAt: Date(), resolvedAt: nil))
            return AudioVideoIndexResult(assetID: asset.id, state: .failed, chunkCount: 0, sampledFrameCount: 0, failureCategory: failure.category)
        }
    }

    public func pauseIndexing(queue: IndexQueueActor, progressStore: IndexProgressStore? = nil) async {
        await queue.pause()
        if let progressStore { await progressStore.publish(await queue.snapshot()) }
    }

    public func resumeIndexing(queue: IndexQueueActor, cancellation: IndexCancellation? = nil, progressStore: IndexProgressStore? = nil) async {
        cancellation?.reset()
        await queue.resume()
        if let progressStore { await progressStore.publish(await queue.snapshot()) }
    }

    public func cancelIndexing(queue: IndexQueueActor, cancellation: IndexCancellation, progressStore: IndexProgressStore? = nil) async {
        cancellation.cancel()
        await queue.cancelRunning()
        if let progressStore { await progressStore.publish(await queue.snapshot()) }
    }

    public func retryFailure(_ failure: IndexFailure, storage: StorageRepositories, queue: IndexQueueActor) async throws {
        let job = recoveryJob(for: failure, fallbackType: .indexAsset)
        try await storage.jobs.enqueue(job)
        await queue.enqueue(job)
        try await storage.failures.resolve(id: failure.id, at: Date())
        if let assetID = failure.assetID {
            try await storage.assets.updateIndexState(id: assetID, state: .queued, lastIndexedAt: nil)
        }
    }

    public func ignoreFailure(_ failure: IndexFailure, storage: StorageRepositories) async throws {
        try await storage.failures.resolve(id: failure.id, at: Date())
        if let assetID = failure.assetID {
            try await storage.assets.updateIndexState(id: assetID, state: .failed, lastIndexedAt: nil)
        }
    }

    public func reindexAsset(_ assetID: UUID, storage: StorageRepositories, queue: IndexQueueActor, priority: Int = 50) async throws {
        let job = IndexJob(jobType: .reindexAsset, assetID: assetID, priority: priority, status: .queued)
        try await storage.jobs.enqueue(job)
        await queue.enqueue(job)
        try await storage.assets.updateIndexState(id: assetID, state: .queued, lastIndexedAt: nil)
    }

    public func reindexFolder(_ folderID: UUID, storage: StorageRepositories, queue: IndexQueueActor, priority: Int = 75) async throws {
        let job = IndexJob(jobType: .reindexFolder, watchedFolderID: folderID, priority: priority, status: .queued)
        try await storage.jobs.enqueue(job)
        await queue.enqueue(job)
        let assets = try await storage.assets.list(watchedFolderID: folderID)
        for asset in assets {
            try await storage.assets.updateIndexState(id: asset.id, state: .queued, lastIndexedAt: nil)
        }
    }

    public func rebuildQueue(storage: StorageRepositories, queue: IndexQueueActor) async throws {
        let folders = try await storage.watchedFolders.list().filter { $0.isEnabled }
        for folder in folders {
            try await reindexFolder(folder.id, storage: storage, queue: queue, priority: 100)
        }
    }

    public func cleanupMissing(storage: StorageRepositories) async throws -> Int {
        let assets = try await storage.assets.list(watchedFolderID: nil).filter { $0.indexState == .missing }
        for asset in assets {
            try await storage.chunks.removeByAsset(id: asset.id)
            try await storage.extractionRecords.removeByAsset(id: asset.id)
            try await storage.assets.remove(id: asset.id)
        }
        return assets.count
    }

    private func recoveryJob(for failure: IndexFailure, fallbackType: JobType) -> IndexJob {
        let type: JobType
        switch failure.retryability {
        case .rebuildIndex: type = .reindexFolder
        default: type = fallbackType
        }
        return IndexJob(
            jobType: failure.watchedFolderID != nil && failure.assetID == nil ? .reindexFolder : type,
            watchedFolderID: failure.watchedFolderID,
            assetID: failure.assetID,
            priority: 90,
            status: .queued,
            lastErrorCategory: nil
        )
    }

    private static func durationSummary(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func saveRecord(
        _ storage: StorageRepositories,
        assetID: UUID,
        stage: ExtractionStage,
        status: IndexState,
        summary: String,
        error: FailureCategory? = nil,
        timestampStart: Double? = nil,
        timestampEnd: Double? = nil,
        confidence: Double? = nil
    ) async throws -> UUID {
        let id = UUID()
        try await storage.extractionRecords.save(record(assetID: assetID, stage: stage, status: status, summary: summary, error: error, id: id, timestampStart: timestampStart, timestampEnd: timestampEnd, confidence: confidence))
        return id
    }

    private func record(
        assetID: UUID,
        stage: ExtractionStage,
        providerID: String? = nil,
        status: IndexState,
        summary: String,
        error: FailureCategory? = nil,
        id: UUID = UUID(),
        timestampStart: Double? = nil,
        timestampEnd: Double? = nil,
        confidence: Double? = nil
    ) -> ExtractionRecord {
        ExtractionRecord(
            id: id,
            assetID: assetID,
            stage: stage,
            providerID: providerID,
            providerMode: providerID == nil ? .localFramework : .localLoopback,
            status: status,
            outputSummary: String(summary.prefix(240)),
            confidence: confidence,
            pageNumber: nil,
            timestampStart: timestampStart,
            timestampEnd: timestampEnd,
            errorCategory: error,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
