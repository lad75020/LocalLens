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

    private func saveRecord(
        _ storage: StorageRepositories,
        assetID: UUID,
        stage: ExtractionStage,
        status: IndexState,
        summary: String,
        error: FailureCategory? = nil
    ) async throws -> UUID {
        let id = UUID()
        try await storage.extractionRecords.save(record(assetID: assetID, stage: stage, status: status, summary: summary, error: error, id: id))
        return id
    }

    private func record(
        assetID: UUID,
        stage: ExtractionStage,
        providerID: String? = nil,
        status: IndexState,
        summary: String,
        error: FailureCategory? = nil,
        id: UUID = UUID()
    ) -> ExtractionRecord {
        ExtractionRecord(
            id: id,
            assetID: assetID,
            stage: stage,
            providerID: providerID,
            providerMode: providerID == nil ? .localFramework : .localLoopback,
            status: status,
            outputSummary: String(summary.prefix(240)),
            confidence: nil,
            pageNumber: nil,
            timestampStart: nil,
            timestampEnd: nil,
            errorCategory: error,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
