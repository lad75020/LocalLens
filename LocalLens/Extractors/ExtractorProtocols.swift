import CoreGraphics
import Foundation

public protocol ExtractorService: Sendable {
    associatedtype Output: Sendable
    func extract(from url: URL) async throws -> Output
}

public enum ExtractionFailure: Error, Equatable, Sendable, LocalizedError {
    case failed(category: FailureCategory, retryability: Retryability, safeMessage: String)

    public var category: FailureCategory {
        switch self { case .failed(let category, _, _): category }
    }

    public var retryability: Retryability {
        switch self { case .failed(_, let retryability, _): retryability }
    }

    public var errorDescription: String? {
        switch self { case .failed(_, _, let safeMessage): safeMessage }
    }

    public static func map(_ error: Error, defaultCategory: FailureCategory = .unknownRedacted) -> ExtractionFailure {
        if let failure = error as? ExtractionFailure { return failure }
        if error is CancellationError {
            return .failed(category: .cancelled, retryability: .retry, safeMessage: "Indexing was cancelled.")
        }
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileReadNoPermissionError {
            return .failed(category: .permissionDenied, retryability: .reauthorize, safeMessage: "LocalLens does not have permission to read this file.")
        }
        return .failed(category: defaultCategory, retryability: .retry, safeMessage: "Extraction failed with a redacted local error.")
    }
}

public struct ThumbnailResult: Equatable, Sendable {
    public let assetID: UUID
    public let thumbnailURL: URL
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let byteCount: Int
}

public struct RecognizedText: Equatable, Sendable {
    public let text: String
    public let confidence: Double
    public let pageNumber: Int?
}

public struct VisualLabel: Equatable, Sendable {
    public let label: String
    public let confidence: Double
}

public struct PageExtraction: Equatable, Sendable {
    public let pageNumber: Int
    public let selectableText: String
    public let ocrText: String
    public let failureCategory: FailureCategory?

    public var combinedText: String {
        [selectableText, ocrText]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

public struct ImageExtractionResult: Equatable, Sendable {
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let recognizedText: [RecognizedText]
    public let visualLabels: [VisualLabel]
    public let failureCategory: FailureCategory?

    public var dimensions: String { "\(pixelWidth)x\(pixelHeight)" }
    public var text: String { recognizedText.map(\.text).joined(separator: "\n") }
}

public struct PDFExtractionResult: Equatable, Sendable {
    public let pageCount: Int
    public let pages: [PageExtraction]
    public let failureCategory: FailureCategory?

    public var text: String { pages.map(\.combinedText).filter { !$0.isEmpty }.joined(separator: "\n") }
    public var partialFailureCount: Int { pages.filter { $0.failureCategory != nil }.count }
}

public struct TranscriptSegment: Equatable, Sendable {
    public let text: String
    public let timestampStart: Double
    public let timestampEnd: Double
    public let confidence: Double?

    public init(text: String, timestampStart: Double, timestampEnd: Double, confidence: Double? = nil) {
        self.text = text
        self.timestampStart = max(0, timestampStart)
        self.timestampEnd = max(self.timestampStart, timestampEnd)
        self.confidence = confidence
    }
}

public protocol AudioTranscriptionProvider: Sendable {
    func transcriptSegments(for url: URL, durationSeconds: Double) async throws -> [TranscriptSegment]
}

public struct AudioExtractionResult: Equatable, Sendable {
    public let durationSeconds: Double
    public let transcriptSegments: [TranscriptSegment]
    public let failureCategory: FailureCategory?

    public var transcriptText: String { transcriptSegments.map(\.text).joined(separator: "\n") }
}

public struct VideoFrameScene: Equatable, Sendable {
    public let timestamp: Double
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let recognizedText: [RecognizedText]
    public let visualLabels: [VisualLabel]

    public var combinedText: String { recognizedText.map(\.text).joined(separator: "\n") }
    public var labelText: String { visualLabels.map(\.label).joined(separator: "\n") }
}

public protocol VideoFrameAnalyzer: Sendable {
    func analyzeFrame(at timestamp: Double, image: CGImage) async -> (recognizedText: [RecognizedText], visualLabels: [VisualLabel])
}

public struct VideoSceneExtractionResult: Equatable, Sendable {
    public let durationSeconds: Double
    public let keyframes: [VideoFrameScene]
    public let transcriptSegments: [TranscriptSegment]
    public let sampledFrameCount: Int
    public let failureCategory: FailureCategory?

    public var transcriptText: String { transcriptSegments.map(\.text).joined(separator: "\n") }
    public var sceneLabelText: String { keyframes.flatMap(\.visualLabels).map(\.label).joined(separator: "\n") }
}

public struct EmbeddingStageResult: Equatable, Sendable {
    public let chunks: [SearchableChunk]
    public let providerID: String?
    public let state: IndexState
    public let failureCategory: FailureCategory?
}

public struct ImagePDFIndexResult: Equatable, Sendable {
    public let assetID: UUID
    public let state: IndexState
    public let thumbnailURL: URL?
    public let chunkCount: Int
    public let failureCategory: FailureCategory?
}

public struct AudioVideoIndexResult: Equatable, Sendable {
    public let assetID: UUID
    public let state: IndexState
    public let chunkCount: Int
    public let sampledFrameCount: Int
    public let failureCategory: FailureCategory?
}

public protocol EmbeddingClient: Sendable {
    func embeddings(model: String, inputs: [String]) async throws -> [[Float]]
}

extension OpenAICompatibleClient: EmbeddingClient {}
