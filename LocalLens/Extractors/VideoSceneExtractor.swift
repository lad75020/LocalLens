import AVFoundation
import Foundation
import Vision

public struct VisionVideoFrameAnalyzer: VideoFrameAnalyzer, Sendable {
    public init() {}

    public func analyzeFrame(at timestamp: Double, image: CGImage) async -> (recognizedText: [RecognizedText], visualLabels: [VisualLabel]) {
        async let text = recognizeText(in: image)
        async let labels = classify(image: image)
        return await (text, labels + fallbackLabels(for: image))
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
                    let observations = (request.results ?? []).compactMap { observation -> RecognizedText? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        let value = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !value.isEmpty else { return nil }
                        return RecognizedText(text: value, confidence: Double(candidate.confidence), pageNumber: nil)
                    }
                    continuation.resume(returning: observations)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func classify(image: CGImage) async -> [VisualLabel] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    continuation.resume(returning: Array((request.results ?? []).prefix(5).map {
                        VisualLabel(label: $0.identifier, confidence: Double($0.confidence))
                    }))
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func fallbackLabels(for image: CGImage) -> [VisualLabel] {
        [
            VisualLabel(label: image.width >= image.height ? "landscape video frame" : "portrait video frame", confidence: 0.55),
            VisualLabel(label: "video frame", confidence: 0.50)
        ]
    }
}

public struct VideoSceneExtractor: ExtractorService, Sendable {
    public let maxSampledFrames: Int
    public let transcriptProvider: (any AudioTranscriptionProvider)?
    public let frameAnalyzer: any VideoFrameAnalyzer
    public let providerTimeoutSeconds: TimeInterval

    public init(
        maxSampledFrames: Int = BuildConfiguration.videoMaxSampledFrames,
        transcriptProvider: (any AudioTranscriptionProvider)? = nil,
        frameAnalyzer: any VideoFrameAnalyzer = VisionVideoFrameAnalyzer(),
        providerTimeoutSeconds: TimeInterval = BuildConfiguration.providerTimeoutSeconds
    ) {
        self.maxSampledFrames = max(1, maxSampledFrames)
        self.transcriptProvider = transcriptProvider
        self.frameAnalyzer = frameAnalyzer
        self.providerTimeoutSeconds = max(0.05, providerTimeoutSeconds)
    }

    public func extract(from url: URL) async throws -> VideoSceneExtractionResult {
        do {
            let asset = AVURLAsset(url: url)
            let duration = try await durationSeconds(for: asset)
            let timestamps = sampleTimestamps(durationSeconds: duration)
            let keyframes = try await extractKeyframes(from: asset, timestamps: timestamps)
            let transcript = await transcriptSegments(for: url, durationSeconds: duration)
            let failure = transcript.failureCategory ?? (keyframes.isEmpty ? FailureCategory.corruptedMedia : nil)
            return VideoSceneExtractionResult(
                durationSeconds: duration,
                keyframes: keyframes,
                transcriptSegments: transcript.segments,
                sampledFrameCount: timestamps.count,
                failureCategory: failure
            )
        } catch let failure as ExtractionFailure {
            throw failure
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
        }
    }

    private func durationSeconds(for asset: AVURLAsset) async throws -> Double {
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else {
            throw ExtractionFailure.failed(
                category: .corruptedMedia,
                retryability: .notRetryable,
                safeMessage: "Video duration could not be read."
            )
        }
        return seconds
    }

    private func sampleTimestamps(durationSeconds: Double) -> [Double] {
        let count = min(maxSampledFrames, max(1, Int(ceil(durationSeconds / 10.0))))
        guard count > 1 else { return [min(0.25, durationSeconds / 2)] }
        return (0..<count).map { index in
            let fraction = Double(index + 1) / Double(count + 1)
            return min(max(0.05, durationSeconds * fraction), max(0.05, durationSeconds - 0.05))
        }
    }

    private func extractKeyframes(from asset: AVURLAsset, timestamps: [Double]) async throws -> [VideoFrameScene] {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 1280)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)

        var scenes: [VideoFrameScene] = []
        for timestamp in timestamps {
            try Task.checkCancellation()
            do {
                let requested = CMTime(seconds: timestamp, preferredTimescale: 600)
                let image = try generator.copyCGImage(at: requested, actualTime: nil)
                let analysis = await frameAnalyzer.analyzeFrame(at: timestamp, image: image)
                scenes.append(VideoFrameScene(
                    timestamp: timestamp,
                    pixelWidth: image.width,
                    pixelHeight: image.height,
                    recognizedText: analysis.recognizedText,
                    visualLabels: deduplicated(analysis.visualLabels)
                ))
            } catch {
                continue
            }
        }
        return scenes
    }

    private func transcriptSegments(for url: URL, durationSeconds: Double) async -> (segments: [TranscriptSegment], failureCategory: FailureCategory?) {
        guard let transcriptProvider else { return ([], nil) }
        do {
            let segments = try await withTimeout(seconds: providerTimeoutSeconds) {
                try await transcriptProvider.transcriptSegments(for: url, durationSeconds: durationSeconds)
            }
            return (segments.prefix(240).compactMap { segment in
                let text = String(segment.text.prefix(BuildConfiguration.maxPromptCharacters)).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                return TranscriptSegment(
                    text: text,
                    timestampStart: min(max(0, segment.timestampStart), durationSeconds),
                    timestampEnd: min(max(segment.timestampStart, segment.timestampEnd), durationSeconds),
                    confidence: segment.confidence
                )
            }, nil)
        } catch is CancellationError {
            return ([], .cancelled)
        } catch let failure as ExtractionFailure {
            return ([], failure.category)
        } catch {
            return ([], .modelUnavailable)
        }
    }

    private func deduplicated(_ labels: [VisualLabel]) -> [VisualLabel] {
        var seen = Set<String>()
        return labels.filter { label in
            let key = label.label.normalizedForSearch
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}
