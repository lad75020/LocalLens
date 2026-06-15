import Foundation

public struct SearchableChunkBuilder: Sendable { public init() {}; public func chunks(text: String, assetID: UUID) -> [SearchableChunk] { [SearchableChunk(id: UUID(), assetID: assetID, extractionRecordID: nil, chunkType: .visibleText, text: String(text.prefix(2000)), normalizedText: text.lowercased(), embedding: nil, embeddingModel: nil, pageNumber: nil, timestampStart: nil, timestampEnd: nil, confidence: nil, createdAt: Date())] } }
