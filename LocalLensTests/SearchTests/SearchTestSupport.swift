import Foundation
@testable import LocalLens

enum SearchTestSupport {
    static func storage(database: LocalLensDatabase) -> StorageRepositories {
        StorageRepositories(
            watchedFolders: SQLiteWatchedFolderRepository(database: database),
            assets: SQLiteMediaAssetRepository(database: database),
            extractionRecords: SQLiteExtractionRecordRepository(database: database),
            chunks: SQLiteSearchableChunkRepository(database: database),
            jobs: SQLiteIndexJobRepository(database: database),
            failures: SQLiteIndexFailureRepository(database: database),
            providers: SQLiteProviderSettingsRepository(database: database),
            appSettings: SQLiteAppSettingsRepository(database: database),
            maintenance: StorageMaintenanceRepository(database: database)
        )
    }

    static func folder(id: UUID = UUID(), displayName: String = "Fixtures", displayPath: String = "/redacted/Fixtures") -> WatchedFolder {
        WatchedFolder(id: id, displayName: displayName, bookmarkData: Data([1]), originalPathHash: "hash", displayPath: displayPath)
    }

    static func asset(
        id: UUID = UUID(),
        folderID: UUID,
        filename: String,
        mediaType: MediaType = .image,
        indexState: IndexState = .complete,
        thumbnailState: IndexState = .complete,
        relativePath: String? = nil
    ) -> MediaAsset {
        let now = Date()
        return MediaAsset(
            id: id,
            watchedFolderID: folderID,
            fileIdentity: id.uuidString,
            pathRelativeToFolder: relativePath ?? filename,
            pathHash: "path-\(id.uuidString)",
            filename: filename,
            mediaType: mediaType,
            contentType: mediaType == .pdf ? "com.adobe.pdf" : "public.image",
            sizeBytes: 42,
            createdAtFile: now,
            modifiedAtFile: now,
            indexedFileSignature: "sig-\(id.uuidString)",
            dimensions: nil,
            durationSeconds: nil,
            pageCount: mediaType == .pdf ? 2 : nil,
            thumbnailState: thumbnailState,
            indexState: indexState,
            lastIndexedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }

    static func chunk(
        id: UUID = UUID(),
        assetID: UUID,
        type: MatchReason,
        text: String,
        embedding: [Float]? = nil,
        embeddingModel: String? = nil,
        pageNumber: Int? = nil,
        timestampStart: Double? = nil,
        timestampEnd: Double? = nil
    ) -> SearchableChunk {
        SearchableChunk(
            id: id,
            assetID: assetID,
            extractionRecordID: nil,
            chunkType: type,
            text: text,
            normalizedText: text.normalizedForSearch,
            embedding: embedding,
            embeddingModel: embeddingModel,
            pageNumber: pageNumber,
            timestampStart: timestampStart,
            timestampEnd: timestampEnd,
            confidence: 0.9,
            createdAt: Date()
        )
    }
}
