import Foundation
import XCTest
@testable import LocalLens

final class MediaDiscoveryServiceTests: XCTestCase {
    func testRecursiveDiscoveryFindsSupportedMediaAndIgnoresUnsupportedHiddenPackagesAndSymlinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let nested = root.appendingPathComponent("Nested", isDirectory: true)
        let hidden = root.appendingPathComponent(".hidden", isDirectory: true)
        let package = root.appendingPathComponent("Archive.photoslibrary", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: hidden, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)

        try Data("png".utf8).write(to: root.appendingPathComponent("one.PNG"))
        try Data("pdf".utf8).write(to: nested.appendingPathComponent("two.pdf"))
        try Data("mp3".utf8).write(to: nested.appendingPathComponent("three.mp3"))
        try Data("mov".utf8).write(to: nested.appendingPathComponent("four.mov"))
        try Data("txt".utf8).write(to: nested.appendingPathComponent("ignore.txt"))
        try Data("hidden".utf8).write(to: hidden.appendingPathComponent("hidden.png"))
        try Data("package".utf8).write(to: package.appendingPathComponent("package.png"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("linked.png"), withDestinationURL: nested.appendingPathComponent("two.pdf"))

        let folderID = UUID()
        let result = try MediaDiscoveryService().discover(in: root, watchedFolderID: folderID)
        let relativePaths = result.assets.map(\.pathRelativeToFolder).sorted()

        XCTAssertEqual(relativePaths, ["Nested/four.mov", "Nested/three.mp3", "Nested/two.pdf", "one.PNG"])
        XCTAssertEqual(Set(result.assets.map(\.mediaType)), Set([.image, .pdf, .audio, .video]))
        XCTAssertTrue(result.unsupportedFileCount >= 1)
        XCTAssertTrue(result.skippedFileCount >= 1)
        XCTAssertTrue(result.jobs.contains { $0.jobType == .discoverFolder && $0.watchedFolderID == folderID })
        XCTAssertEqual(result.jobs.filter { $0.jobType == .indexAsset }.count, result.assets.count)
    }

    func testResolverCoversSupportedExtensions() {
        let resolver = MediaTypeResolver()
        let expectations: [String: MediaType] = [
            "png": .image, "jpg": .image, "jpeg": .image, "heic": .image, "tiff": .image, "webp": .image,
            "pdf": .pdf,
            "mp3": .audio, "m4a": .audio, "wav": .audio, "aac": .audio,
            "mp4": .video, "mov": .video, "m4v": .video
        ]
        for (ext, mediaType) in expectations {
            XCTAssertEqual(resolver.mediaType(for: URL(fileURLWithPath: "fixture.\(ext)")), mediaType, ext)
            XCTAssertNotNil(resolver.contentTypeIdentifier(for: URL(fileURLWithPath: "fixture.\(ext)")), ext)
        }
    }
}
