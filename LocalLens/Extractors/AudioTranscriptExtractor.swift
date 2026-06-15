import AVFoundation
import Foundation

public struct AudioTranscriptExtractor: ExtractorService, Sendable {
    public let transcriptProvider: (any AudioTranscriptionProvider)?
    public let providerTimeoutSeconds: TimeInterval
    public let maxTranscriptSegments: Int

    public init(
        transcriptProvider: (any AudioTranscriptionProvider)? = nil,
        providerTimeoutSeconds: TimeInterval = BuildConfiguration.providerTimeoutSeconds,
        maxTranscriptSegments: Int = 240
    ) {
        self.transcriptProvider = transcriptProvider
        self.providerTimeoutSeconds = max(0.05, providerTimeoutSeconds)
        self.maxTranscriptSegments = max(1, maxTranscriptSegments)
    }

    public func extract(from url: URL) async throws -> AudioExtractionResult {
        do {
            let duration = try await durationSeconds(for: url)
            guard let transcriptProvider else {
                return AudioExtractionResult(
                    durationSeconds: duration,
                    transcriptSegments: [],
                    failureCategory: .modelUnavailable
                )
            }

            do {
                let segments = try await withTimeout(seconds: providerTimeoutSeconds) {
                    try await transcriptProvider.transcriptSegments(for: url, durationSeconds: duration)
                }
                return AudioExtractionResult(
                    durationSeconds: duration,
                    transcriptSegments: bounded(segments, durationSeconds: duration),
                    failureCategory: nil
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch let failure as ExtractionFailure where failure.category == .providerTimeout {
                return AudioExtractionResult(durationSeconds: duration, transcriptSegments: [], failureCategory: .providerTimeout)
            } catch let failure as ExtractionFailure {
                return AudioExtractionResult(durationSeconds: duration, transcriptSegments: [], failureCategory: failure.category)
            } catch {
                return AudioExtractionResult(durationSeconds: duration, transcriptSegments: [], failureCategory: .modelUnavailable)
            }
        } catch let failure as ExtractionFailure {
            throw failure
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
        }
    }

    private func durationSeconds(for url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else {
            throw ExtractionFailure.failed(
                category: .corruptedMedia,
                retryability: .notRetryable,
                safeMessage: "Audio duration could not be read."
            )
        }
        return seconds
    }

    private func bounded(_ segments: [TranscriptSegment], durationSeconds: Double) -> [TranscriptSegment] {
        segments
            .prefix(maxTranscriptSegments)
            .compactMap { segment in
                let text = String(segment.text.prefix(BuildConfiguration.maxPromptCharacters))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                let start = min(max(0, segment.timestampStart), durationSeconds)
                let end = min(max(start, segment.timestampEnd), durationSeconds)
                return TranscriptSegment(text: text, timestampStart: start, timestampEnd: end, confidence: segment.confidence)
            }
    }
}

public func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            let nanoseconds = UInt64(max(0.001, seconds) * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanoseconds)
            throw ExtractionFailure.failed(
                category: .providerTimeout,
                retryability: .retry,
                safeMessage: "Local provider timed out while processing media."
            )
        }
        guard let value = try await group.next() else { throw CancellationError() }
        group.cancelAll()
        return value
    }
}
