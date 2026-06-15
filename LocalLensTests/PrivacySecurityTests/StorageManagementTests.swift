import XCTest
@testable import LocalLens

final class StorageManagementTests: XCTestCase {
    func testStorageUsageDeleteRebuildAndSourcePreservation() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = SearchTestSupport.storage(database: database)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let sourceURL = root.appendingPathComponent("source-fixture.txt")
        try Data("source bytes".utf8).write(to: sourceURL)
        let before = try Data(contentsOf: sourceURL)

        let folder = SearchTestSupport.folder()
        try await storage.watchedFolders.save(folder)
        let asset = SearchTestSupport.asset(folderID: folder.id, filename: "source-fixture.txt")
        try await storage.assets.save(asset)
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: asset.id, type: .filename, text: "source fixture"))

        var usage = try await storage.maintenance.storageUsage()
        XCTAssertEqual(usage.indexedAssetCount, 1)
        XCTAssertGreaterThan(usage.totalBytes, 0)

        try await storage.maintenance.rebuildIndexData()
        usage = try await storage.maintenance.storageUsage()
        XCTAssertGreaterThanOrEqual(usage.queuedJobCount, 1)

        try await storage.maintenance.deleteIndexData()
        let remainingCount = try await storage.maintenance.indexedAssetCount()
        XCTAssertEqual(remainingCount, 0)
        XCTAssertEqual(try Data(contentsOf: sourceURL), before)
    }
}
