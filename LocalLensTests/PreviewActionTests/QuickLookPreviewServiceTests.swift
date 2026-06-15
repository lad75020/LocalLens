import Foundation
import XCTest
@testable import LocalLens

@MainActor
final class QuickLookPreviewServiceTests: XCTestCase {
    func testPreviewValidatesURLStartsSecurityScopeAndPreservesSourceBytes() throws {
        let root = try tempRoot()
        let fileURL = root.appendingPathComponent("photo.jpg")
        let original = Data("private image bytes".utf8)
        try original.write(to: fileURL)
        let counter = AccessCounter()
        let store = bookmarkStore(root: root, counter: counter)
        var previewedURL: URL?
        let service = QuickLookPreviewService(
            resolver: ResultFileResolver(bookmarkStore: store),
            presenter: { url in previewedURL = url; return true }
        )
        let folder = folder(root: root)
        let asset = asset(folder: folder, filename: "photo.jpg")

        var session: QuickLookPreviewSession? = try service.preview(asset: asset, folder: folder)

        XCTAssertEqual(previewedURL?.standardizedFileURL, fileURL.standardizedFileURL)
        XCTAssertEqual(counter.starts, 1)
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
        session = nil
        XCTAssertEqual(counter.stops, 1)
    }

    func testMissingFileProducesSafeMissingErrorAndStopsAccess() throws {
        let root = try tempRoot()
        let counter = AccessCounter()
        let service = QuickLookPreviewService(
            resolver: ResultFileResolver(bookmarkStore: bookmarkStore(root: root, counter: counter)),
            presenter: { _ in XCTFail("Missing files must not be presented"); return true }
        )
        let folder = folder(root: root)
        let missing = asset(folder: folder, filename: "missing.jpg")

        XCTAssertThrowsError(try service.preview(asset: missing, folder: folder)) { error in
            XCTAssertEqual(error as? ResultActionError, .missingFile)
            XCTAssertFalse(error.localizedDescription.contains(root.path))
        }
        XCTAssertEqual(counter.starts, 1)
        XCTAssertEqual(counter.stops, 1)
    }

    func testTraversalRelativePathIsRejectedBeforePreview() throws {
        let root = try tempRoot()
        let service = QuickLookPreviewService(
            resolver: ResultFileResolver(bookmarkStore: bookmarkStore(root: root, counter: AccessCounter())),
            presenter: { _ in XCTFail("Invalid paths must not be presented"); return true }
        )
        let folder = folder(root: root)
        let escaping = asset(folder: folder, filename: "secret.jpg", relativePath: "../secret.jpg")

        XCTAssertThrowsError(try service.preview(asset: escaping, folder: folder)) { error in
            XCTAssertEqual(error as? ResultActionError, .invalidRelativePath)
        }
    }
}

final class AccessCounter: @unchecked Sendable {
    var starts = 0
    var stops = 0
}

func tempRoot() throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalLensPreview-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return root
}

func bookmarkStore(root: URL, counter: AccessCounter) -> SecurityScopedBookmarkStore {
    SecurityScopedBookmarkStore(
        createBookmarkData: { Data($0.path.utf8) },
        resolveBookmarkData: { _ in SecurityScopedBookmarkResolution(url: root, isStale: false) },
        startAccessing: { _ in counter.starts += 1; return true },
        stopAccessing: { _ in counter.stops += 1 }
    )
}

func folder(root: URL, id: UUID = UUID()) -> WatchedFolder {
    WatchedFolder(id: id, displayName: root.lastPathComponent, bookmarkData: Data(root.path.utf8), originalPathHash: "hash", displayPath: root.path)
}

func asset(folder: WatchedFolder, filename: String, relativePath: String? = nil, id: UUID = UUID()) -> MediaAsset {
    let now = Date()
    return MediaAsset(
        id: id,
        watchedFolderID: folder.id,
        fileIdentity: id.uuidString,
        pathRelativeToFolder: relativePath ?? filename,
        pathHash: "path-\(id.uuidString)",
        filename: filename,
        mediaType: .image,
        contentType: "public.jpeg",
        sizeBytes: 1,
        createdAtFile: now,
        modifiedAtFile: now,
        indexedFileSignature: "sig",
        dimensions: nil,
        durationSeconds: nil,
        pageCount: nil,
        thumbnailState: .complete,
        indexState: .complete,
        lastIndexedAt: now,
        createdAt: now,
        updatedAt: now
    )
}
