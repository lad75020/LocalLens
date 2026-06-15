import AppKit
import Foundation
import ImageIO
import Vision

public struct ImageExtractor: ExtractorService, Sendable {
    public init() {}

    public func extract(from url: URL) async throws -> ImageExtractionResult {
        do {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "Image could not be decoded.")
            }
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let width = (properties?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue
            let height = (properties?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCache: false] as CFDictionary) else {
                throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "Image pixels could not be decoded.")
            }

            let recognizedText = await recognizeText(in: cgImage)
            let labels = await classify(cgImage: cgImage, url: url, width: width ?? cgImage.width, height: height ?? cgImage.height)
            return ImageExtractionResult(
                pixelWidth: width ?? cgImage.width,
                pixelHeight: height ?? cgImage.height,
                recognizedText: recognizedText,
                visualLabels: labels,
                failureCategory: nil
            )
        } catch let failure as ExtractionFailure {
            throw failure
        } catch {
            throw ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
        }
    }

    private func recognizeText(in image: CGImage) async -> [RecognizedText] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let observations = (request.results ?? [])
                        .compactMap { observation -> RecognizedText? in
                            guard let candidate = observation.topCandidates(1).first else { return nil }
                            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return nil }
                            return RecognizedText(text: text, confidence: Double(candidate.confidence), pageNumber: nil)
                        }
                    continuation.resume(returning: observations)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func classify(cgImage image: CGImage, url: URL, width: Int, height: Int) async -> [VisualLabel] {
        let visionLabels = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let labels = (request.results ?? [])
                        .prefix(5)
                        .map { VisualLabel(label: $0.identifier, confidence: Double($0.confidence)) }
                    continuation.resume(returning: Array(labels))
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }

        var labels = visionLabels
        let lowerName = url.lastPathComponent.lowercased()
        if lowerName.contains("screen") || lowerName.contains("shot") {
            labels.append(VisualLabel(label: "screenshot", confidence: 0.70))
        }
        labels.append(VisualLabel(label: width >= height ? "landscape image" : "portrait image", confidence: 0.55))
        labels.append(VisualLabel(label: "image", confidence: 0.50))

        var seen = Set<String>()
        return labels.filter { label in
            let key = label.label.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}
