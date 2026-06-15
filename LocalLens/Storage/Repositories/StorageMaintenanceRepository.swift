import Foundation

public struct StorageUsageSnapshot: Equatable, Sendable {
    public var databaseBytes: Int64
    public var cacheBytes: Int64
    public var indexedAssetCount: Int
    public var queuedJobCount: Int

    public var totalBytes: Int64 { databaseBytes + cacheBytes }

    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

public extension StorageMaintenanceRepositoryProtocol {
    func storageUsage() async throws -> StorageUsageSnapshot {
        StorageUsageSnapshot(databaseBytes: 0, cacheBytes: 0, indexedAssetCount: try await indexedAssetCount(), queuedJobCount: 0)
    }

    func rebuildIndexData() async throws {}
    func cleanupCacheData() async throws {}
}

public extension StorageMaintenanceRepository {
    func storageUsage() async throws -> StorageUsageSnapshot {
        let databaseBytes = Self.fileSize(database.databaseURL)
        let cacheBytes = Self.directorySize(database.cacheRootURL)
        let assets = try await database.scalarInt("SELECT COUNT(*) AS count FROM media_assets;")
        let queued = try await database.scalarInt("SELECT COUNT(*) AS count FROM index_jobs WHERE status = ?;", bindings: [.text(IndexState.queued.rawValue)])
        return StorageUsageSnapshot(databaseBytes: databaseBytes, cacheBytes: cacheBytes, indexedAssetCount: assets, queuedJobCount: queued)
    }

    func rebuildIndexData() async throws {
        let folders = try await database.query("SELECT id FROM watched_folders WHERE is_enabled = 1 ORDER BY created_at ASC;")
        try await deleteIndexData()
        for folder in folders {
            guard let id = folder["id"].stringValue else { continue }
            try await database.execute(
                """
                INSERT OR REPLACE INTO index_jobs
                (id, job_type, watched_folder_id, asset_id, priority, status, attempt_count, progress_completed, created_at)
                VALUES (?, ?, ?, NULL, ?, ?, 0, 0, ?);
                """,
                bindings: [.text(UUID().uuidString), .text(JobType.reindexFolder.rawValue), .text(id), .integer(100), .text(IndexState.queued.rawValue), .real(Date().timeIntervalSince1970)]
            )
        }
    }

    func cleanupCacheData() async throws {
        let root = database.cacheRootURL
        guard FileManager.default.fileExists(atPath: root.path) else { return }
        let protectedNames: Set<String> = ["Diagnostics"]
        let contents = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        for url in contents where !protectedNames.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("Thumbnails", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("Transcripts", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("Keyframes", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("Temporary", isDirectory: true), withIntermediateDirectories: true)
    }

    private static func fileSize(_ url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
    }

    private static func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
