import Foundation
import XCTest
@testable import LocalLens

final class AudioTranscriptExtractorTests: XCTestCase {
    func testAudioDurationMetadataAndLocalTranscriptChunks() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try MediaFixtureFactory.writeWAV(durationSeconds: 1.2, in: root)
        let provider = StubTranscriptProvider(segments: [
            TranscriptSegment(text: "spoken local lens phrase", timestampStart: 0.1, timestampEnd: 0.8, confidence: 0.91)
        ])

        let result = try await AudioTranscriptExtractor(transcriptProvider: provider).extract(from: url)

        XCTAssertGreaterThan(result.durationSeconds, 1.0)
        XCTAssertEqual(result.transcriptSegments.count, 1)
        XCTAssertEqual(result.transcriptSegments.first?.text, "spoken local lens phrase")
        XCTAssertEqual(result.failureCategory, nil)
    }

    func testProviderUnavailableFallsBackToDurationOnlyPartialSignal() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try MediaFixtureFactory.writeWAV(durationSeconds: 0.8, in: root)

        let result = try await AudioTranscriptExtractor(transcriptProvider: nil).extract(from: url)

        XCTAssertGreaterThan(result.durationSeconds, 0)
        XCTAssertTrue(result.transcriptSegments.isEmpty)
        XCTAssertEqual(result.failureCategory, .modelUnavailable)
    }

    func testCorruptAudioMapsToSafeFailureCategory() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try MediaFixtureFactory.writeCorruptMedia(in: root)

        do {
            _ = try await AudioTranscriptExtractor().extract(from: url)
            XCTFail("Corrupt audio should fail")
        } catch let failure as ExtractionFailure {
            XCTAssertEqual(failure.category, .corruptedMedia)
            XCTAssertFalse(failure.localizedDescription.contains(url.path))
        }
    }
}

final class StubTranscriptProvider: AudioTranscriptionProvider, @unchecked Sendable {
    enum Mode { case immediate, sleep }

    private let segments: [TranscriptSegment]
    private let mode: Mode

    init(segments: [TranscriptSegment], mode: Mode = .immediate) {
        self.segments = segments
        self.mode = mode
    }

    func transcriptSegments(for url: URL, durationSeconds: Double) async throws -> [TranscriptSegment] {
        switch mode {
        case .immediate:
            return segments
        case .sleep:
            try await Task.sleep(nanoseconds: 500_000_000)
            return segments
        }
    }
}
