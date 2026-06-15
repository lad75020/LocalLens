import Foundation
import XCTest
@testable import LocalLens

@MainActor
final class ResultActionServiceTests: XCTestCase {
    func testRevealOpenCopyPathCopySnippetAndSourceBytePreservation() async throws {
        let root = try tempRoot()
        let fileURL = root.appendingPathComponent("sunset.jpg")
        let original = Data("source bytes stay untouched".utf8)
        try original.write(to: fileURL)
        let folder = folder(root: root)
        let mediaAsset = asset(folder: folder, filename: "sunset.jpg")
        let storage = try await storageWith(folder: folder, asset: mediaAsset)
        let counter = AccessCounter()
        let resolver = ResultFileResolver(bookmarkStore: bookmarkStore(root: root, counter: counter))
        var revealed: [URL] = []
        var opened: [URL] = []
        var copied: [String] = []
        let service = ResultActionService(
            quickLookPreviewService: QuickLookPreviewService(resolver: resolver, presenter: { _ in true }),
            finderRevealService: FinderRevealService(
                resolver: resolver,
                revealHandler: { revealed.append($0) },
                openHandler: { opened.append($0); return true }
            ),
            clipboardActionService: ClipboardActionService(
                resolver: resolver,
                writer: { copied.append($0); return true }
            )
        )
        let result = dto(asset: mediaAsset, snippet: "A private snippet inside \(root.path) should be redacted and bounded.")

        let reveal = await service.perform(.revealInFinder, result: result, storage: storage)
        let open = await service.perform(.openDefault, result: result, storage: storage)
        let copyPath = await service.perform(.copyPath, result: result, storage: storage)
        let copySnippet = await service.perform(.copySnippet, result: result, storage: storage)

        XCTAssertEqual(reveal.safeMessage, "Revealed in Finder.")
        XCTAssertEqual(open.safeMessage, "Opened in the default app.")
        XCTAssertEqual(copyPath.safeMessage, "Source path copied.")
        XCTAssertEqual(copySnippet.safeMessage, "Snippet copied.")
        XCTAssertEqual(revealed.map(\.standardizedFileURL), [fileURL.standardizedFileURL])
        XCTAssertEqual(opened.map(\.standardizedFileURL), [fileURL.standardizedFileURL])
        XCTAssertTrue(copied.contains(fileURL.path))
        let copiedSnippet = try XCTUnwrap(copied.last)
        XCTAssertLessThanOrEqual(copiedSnippet.count, ClipboardActionService.maxSnippetCharacters)
        XCTAssertFalse(copiedSnippet.contains(root.path))
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
    }

    func testMissingFileDisablesDangerousOperationsWithSafeOutcome() async throws {
        let root = try tempRoot()
        let folder = folder(root: root)
        let mediaAsset = asset(folder: folder, filename: "missing.jpg")
        let storage = try await storageWith(folder: folder, asset: mediaAsset)
        let resolver = ResultFileResolver(bookmarkStore: bookmarkStore(root: root, counter: AccessCounter()))
        let service = ResultActionService(
            finderRevealService: FinderRevealService(resolver: resolver, revealHandler: { _ in XCTFail("Missing files must not be revealed") }),
            clipboardActionService: ClipboardActionService(resolver: resolver, writer: { _ in true })
        )

        let outcome = await service.perform(.revealInFinder, result: dto(asset: mediaAsset, snippet: nil), storage: storage)

        XCTAssertEqual(outcome.safeMessage, ResultActionError.missingFile.localizedDescription)
        XCTAssertFalse(outcome.safeMessage.contains(root.path))
    }

    private func storageWith(folder: WatchedFolder, asset: MediaAsset) async throws -> StorageRepositories {
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = SearchTestSupport.storage(database: db)
        try await storage.watchedFolders.save(folder)
        try await storage.assets.save(asset)
        return storage
    }

    private func dto(asset: MediaAsset, snippet: String?) -> SearchResultDTO {
        SearchResultDTO(
            assetID: asset.id,
            filename: asset.filename,
            mediaType: asset.mediaType,
            folderContext: "Fixtures",
            thumbnailID: nil,
            score: 10,
            matchReasons: [.filename],
            snippet: snippet,
            pageNumber: nil,
            timestampStart: nil,
            timestampEnd: nil,
            isMissing: false
        )
    }
}
