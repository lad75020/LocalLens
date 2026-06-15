import Foundation

public struct SearchableChunkBuilder: Sendable {
    public let maxChunkLength: Int

    public init(maxChunkLength: Int = 2_000) {
        self.maxChunkLength = max(256, maxChunkLength)
    }

    public func chunks(text: String, assetID: UUID) -> [SearchableChunk] {
        makeChunks(assetID: assetID, extractionRecordID: nil, type: .visibleText, text: text)
    }

    public func chunks(
        for asset: MediaAsset,
        imageResult: ImageExtractionResult?,
        pdfResult: PDFExtractionResult?,
        audioResult: AudioExtractionResult? = nil,
        videoResult: VideoSceneExtractionResult? = nil,
        officeResult: OfficeDocumentExtractionResult? = nil,
        extractionRecordIDs: [ExtractionStage: UUID] = [:]
    ) -> [SearchableChunk] {
        var output: [SearchableChunk] = []
        output += makeChunks(
            assetID: asset.id,
            extractionRecordID: nil,
            type: .filename,
            text: asset.filename
        )

        if let imageResult {
            output += makeChunks(
                assetID: asset.id,
                extractionRecordID: extractionRecordIDs[.imageOCR],
                type: .visibleText,
                text: imageResult.text,
                confidence: imageResult.recognizedText.map(\.confidence).max()
            )
            output += makeChunks(
                assetID: asset.id,
                extractionRecordID: extractionRecordIDs[.imageLabels],
                type: .visualLabel,
                text: imageResult.visualLabels.map(\.label).joined(separator: "\n"),
                confidence: imageResult.visualLabels.map(\.confidence).max()
            )
        }

        if let pdfResult {
            for page in pdfResult.pages {
                output += makeChunks(
                    assetID: asset.id,
                    extractionRecordID: extractionRecordIDs[.pdfText],
                    type: .pdfText,
                    text: page.selectableText,
                    pageNumber: page.pageNumber
                )
                output += makeChunks(
                    assetID: asset.id,
                    extractionRecordID: extractionRecordIDs[.pdfOCR],
                    type: .visibleText,
                    text: page.ocrText,
                    pageNumber: page.pageNumber
                )
            }
        }

        if let officeResult {
            output += makeChunks(
                assetID: asset.id,
                extractionRecordID: extractionRecordIDs[.officeDocument],
                type: .officeText,
                text: officeResult.searchableText
            )
            output += makeChunks(
                assetID: asset.id,
                extractionRecordID: extractionRecordIDs[.officeDocument],
                type: .officeSummary,
                text: [officeResult.safeSummary, officeResult.safeSnippet, officeResult.officeKind.rawValue].compactMap { $0 }.joined(separator: "\n")
            )
        }

        if let audioResult {
            output += transcriptChunks(assetID: asset.id, recordID: extractionRecordIDs[.audioTranscript], segments: audioResult.transcriptSegments)
        }

        if let videoResult {
            output += transcriptChunks(assetID: asset.id, recordID: extractionRecordIDs[.videoTranscript], segments: videoResult.transcriptSegments)
            for frame in videoResult.keyframes {
                output += makeChunks(
                    assetID: asset.id,
                    extractionRecordID: extractionRecordIDs[.videoKeyframe],
                    type: .visibleText,
                    text: frame.combinedText,
                    timestampStart: frame.timestamp,
                    timestampEnd: frame.timestamp,
                    confidence: frame.recognizedText.map(\.confidence).max()
                )
                output += makeChunks(
                    assetID: asset.id,
                    extractionRecordID: extractionRecordIDs[.sceneLabels],
                    type: .visualLabel,
                    text: frame.labelText,
                    timestampStart: frame.timestamp,
                    timestampEnd: frame.timestamp,
                    confidence: frame.visualLabels.map(\.confidence).max()
                )
            }
        }

        return output.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func transcriptChunks(assetID: UUID, recordID: UUID?, segments: [TranscriptSegment]) -> [SearchableChunk] {
        segments.flatMap { segment in
            makeChunks(
                assetID: assetID,
                extractionRecordID: recordID,
                type: .transcript,
                text: segment.text,
                timestampStart: segment.timestampStart,
                timestampEnd: segment.timestampEnd,
                confidence: segment.confidence
            )
        }
    }

    public func makeChunks(
        assetID: UUID,
        extractionRecordID: UUID?,
        type: MatchReason,
        text: String,
        pageNumber: Int? = nil,
        timestampStart: Double? = nil,
        timestampEnd: Double? = nil,
        confidence: Double? = nil
    ) -> [SearchableChunk] {
        let cleaned = normalizeWhitespace(text)
        guard !cleaned.isEmpty else { return [] }
        return split(cleaned).map { fragment in
            SearchableChunk(
                id: UUID(),
                assetID: assetID,
                extractionRecordID: extractionRecordID,
                chunkType: type,
                text: fragment,
                normalizedText: normalize(fragment),
                embedding: nil,
                embeddingModel: nil,
                pageNumber: pageNumber,
                timestampStart: timestampStart,
                timestampEnd: timestampEnd,
                confidence: confidence,
                createdAt: Date()
            )
        }
    }

    private func split(_ text: String) -> [String] {
        guard text.count > maxChunkLength else { return [text] }
        var chunks: [String] = []
        var current = ""
        for word in text.split(separator: " ", omittingEmptySubsequences: true) {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count > maxChunkLength, !current.isEmpty {
                chunks.append(current)
                current = String(word)
            } else {
                current = candidate
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks.flatMap { chunk -> [String] in
            if chunk.count <= maxChunkLength { return [chunk] }
            var fragments: [String] = []
            var start = chunk.startIndex
            while start < chunk.endIndex {
                let end = chunk.index(start, offsetBy: maxChunkLength, limitedBy: chunk.endIndex) ?? chunk.endIndex
                fragments.append(String(chunk[start..<end]))
                start = end
            }
            return fragments
        }
    }

    private func normalize(_ text: String) -> String {
        normalizeWhitespace(text)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func normalizeWhitespace(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
