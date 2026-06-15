import CoreGraphics
import Foundation
import XCTest
@testable import LocalLens

final class VideoSceneExtractorTests: XCTestCase {
    func testVideoDurationKeyframesSceneLabelsAndTranscript() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try await MediaFixtureFactory.writeVideo(durationSeconds: 1.5, frameCount: 4, in: root)
        let transcriptProvider = StubTranscriptProvider(segments: [
            TranscriptSegment(text: "video narrator says lighthouse", timestampStart: 0.2, timestampEnd: 1.0, confidence: 0.88)
        ])
        let analyzer = StubFrameAnalyzer()

        let result = try await VideoSceneExtractor(
            maxSampledFrames: 3,
            transcriptProvider: transcriptProvider,
            frameAnalyzer: analyzer
        ).extract(from: url)

        XCTAssertGreaterThan(result.durationSeconds, 0)
        XCTAssertFalse(result.keyframes.isEmpty)
        XCTAssertLessThanOrEqual(result.sampledFrameCount, 3)
        XCTAssertTrue(result.keyframes.contains { !$0.visualLabels.isEmpty })
        XCTAssertTrue(result.keyframes.contains { !$0.recognizedText.isEmpty })
        XCTAssertEqual(result.transcriptSegments.first?.text, "video narrator says lighthouse")
    }

    func testLargeVideoSamplingBounds() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try await MediaFixtureFactory.writeVideo(durationSeconds: 3.0, frameCount: 6, in: root)

        let result = try await VideoSceneExtractor(
            maxSampledFrames: 2,
            frameAnalyzer: StubFrameAnalyzer()
        ).extract(from: url)

        XCTAssertLessThanOrEqual(result.sampledFrameCount, 2)
        XCTAssertLessThanOrEqual(result.keyframes.count, 2)
    }

    func testCorruptVideoMapsToSafeFailureCategory() async throws {
        let root = try MediaFixtureFactory.tempRoot()
        let url = try MediaFixtureFactory.writeCorruptMedia(named: "bad.mov", in: root)

        do {
            _ = try await VideoSceneExtractor(frameAnalyzer: StubFrameAnalyzer()).extract(from: url)
            XCTFail("Corrupt video should fail")
        } catch let failure as ExtractionFailure {
            XCTAssertEqual(failure.category, .corruptedMedia)
            XCTAssertFalse(failure.localizedDescription.contains(url.path))
        }
    }
}

struct StubFrameAnalyzer: VideoFrameAnalyzer, Sendable {
    func analyzeFrame(at timestamp: Double, image: CGImage) async -> (recognizedText: [RecognizedText], visualLabels: [VisualLabel]) {
        (
            [RecognizedText(text: "sampled frame text", confidence: 0.8, pageNumber: nil)],
            [VisualLabel(label: "sampled scene", confidence: 0.7)]
        )
    }
}
