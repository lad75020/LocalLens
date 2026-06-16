import Foundation

public struct GeneratedContentChunkBuilder: Sendable {
    public init() {}

    public func chunks(for records: [GeneratedContentRecord]) -> [SearchableChunk] {
        records
            .filter { !$0.boundedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { record in
                SearchableChunk(
                    id: UUID(),
                    assetID: record.assetID,
                    extractionRecordID: record.extractionRecordID,
                    chunkType: record.outputKind.chunkType,
                    text: record.boundedText,
                    normalizedText: normalize(record.boundedText),
                    embedding: nil,
                    embeddingModel: nil,
                    pageNumber: nil,
                    timestampStart: nil,
                    timestampEnd: nil,
                    confidence: nil,
                    createdAt: record.createdAt
                )
            }
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
