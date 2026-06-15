import Foundation
import XCTest
@testable import LocalLens

final class WatchedFolderRepositoryTests: XCTestCase {
    func testAddEnableDisableRemoveRelaunchAndIndexCleanupWithoutSourceDeletion() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let folders = SQLiteWatchedFolderRepository(database: database)
        let assets = SQLiteMediaAssetRepository(database: database)

        let sourceRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        let sourceFile = sourceRoot.appendingPathComponent("photo.png")
        try Data("not really an image".utf8).write(to: sourceFile)

        var folder = WatchedFolder(
            displayName: "Fixtures",
            bookmarkData: Data("bookmark".utf8),
            originalPathHash: "hash",
            displayPath: sourceRoot.path
        )
        try await folders.save(folder)
        var restored = try await folders.get(id: folder.id)
        XCTAssertEqual(restored?.displayPath, sourceRoot.path)

        folder.isEnabled = false
        try await folders.save(folder)
        restored = try await folders.get(id: folder.id)
        XCTAssertEqual(restored?.isEnabled, false)

        folder.isEnabled = true
        try await folders.save(folder)
        restored = try await folders.get(id: folder.id)
        XCTAssertEqual(restored?.isEnabled, true)

        let asset = MediaAsset(
            id: UUID(),
            watchedFolderID: folder.id,
            fileIdentity: "file-id",
            pathRelativeToFolder: "photo.png",
            pathHash: "path-hash",
            filename: "photo.png",
            mediaType: .image,
            contentType: "public.png",
            sizeBytes: 12,
            createdAtFile: nil,
            modifiedAtFile: nil,
            indexedFileSignature: "sig",
            dimensions: nil,
            durationSeconds: nil,
            pageCount: nil,
            thumbnailState: .missing,
            indexState: .discovered,
            lastIndexedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await assets.save(asset)
        let savedAssets = try await assets.list(watchedFolderID: folder.id)
        XCTAssertEqual(savedAssets.count, 1)

        let relaunchedFolders = SQLiteWatchedFolderRepository(database: database)
        let relaunchedIDs = try await relaunchedFolders.list().map(\.id)
        XCTAssertEqual(relaunchedIDs, [folder.id])

        try await relaunchedFolders.remove(id: folder.id)
        let removedFolder = try await relaunchedFolders.get(id: folder.id)
        XCTAssertNil(removedFolder)
        let remainingAssets = try await assets.list(watchedFolderID: folder.id)
        XCTAssertTrue(remainingAssets.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceFile.path), "Removing a watched folder must not delete source media")
    }
}
