import Foundation

public actor SQLiteWatchedFolderRepository: WatchedFolderRepository {
    private let database: LocalLensDatabase

    public init(database: LocalLensDatabase) {
        self.database = database
    }

    public func save(_ folder: WatchedFolder) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO watched_folders
            (id, display_name, bookmark_data, original_path_hash, display_path, is_enabled, authorization_state, last_scan_started_at, last_scan_completed_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [
                .text(folder.id.uuidString), .text(folder.displayName), .data(folder.bookmarkData), .text(folder.originalPathHash), .text(folder.displayPath), .integer(folder.isEnabled ? 1 : 0), .text(folder.authorizationState.rawValue), date(folder.lastScanStartedAt), date(folder.lastScanCompletedAt), date(folder.createdAt), date(folder.updatedAt)
            ]
        )
    }

    public func get(id: UUID) async throws -> WatchedFolder? {
        try await database.query("SELECT * FROM watched_folders WHERE id = ?;", bindings: [.text(id.uuidString)]).first.map(Self.decode)
    }

    public func list() async throws -> [WatchedFolder] {
        try await database.query("SELECT * FROM watched_folders ORDER BY created_at ASC;").map(Self.decode)
    }

    public func updateAuthorizationState(id: UUID, state: AuthorizationState) async throws {
        try await database.execute("UPDATE watched_folders SET authorization_state = ?, updated_at = ? WHERE id = ?;", bindings: [.text(state.rawValue), date(Date()), .text(id.uuidString)])
    }

    public func remove(id: UUID) async throws {
        try await database.execute("DELETE FROM media_assets WHERE watched_folder_id = ?;", bindings: [.text(id.uuidString)])
        try await database.execute("DELETE FROM index_jobs WHERE watched_folder_id = ?;", bindings: [.text(id.uuidString)])
        try await database.execute("DELETE FROM index_failures WHERE watched_folder_id = ?;", bindings: [.text(id.uuidString)])
        try await database.execute("DELETE FROM watched_folders WHERE id = ?;", bindings: [.text(id.uuidString)])
    }

    private static func decode(_ row: SQLiteRow) -> WatchedFolder {
        WatchedFolder(
            id: uuid(row["id"]),
            displayName: row["display_name"].stringValue ?? "",
            bookmarkData: row["bookmark_data"].dataValue ?? Data(),
            originalPathHash: row["original_path_hash"].stringValue ?? "",
            displayPath: row["display_path"].stringValue ?? "",
            isEnabled: bool(row["is_enabled"]),
            authorizationState: AuthorizationState(rawValue: row["authorization_state"].stringValue ?? "") ?? .needsReauthorization,
            lastScanStartedAt: optionalDate(row["last_scan_started_at"]),
            lastScanCompletedAt: optionalDate(row["last_scan_completed_at"]),
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
            updatedAt: optionalDate(row["updated_at"]) ?? Date(timeIntervalSince1970: 0)
        )
    }
}

public actor SQLiteMediaAssetRepository: MediaAssetRepository {
    private let database: LocalLensDatabase

    public init(database: LocalLensDatabase) { self.database = database }

    public func save(_ asset: MediaAsset) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO media_assets
            (id, watched_folder_id, file_identity, relative_path, path_hash, filename, media_type, content_type, size_bytes, created_at_file, modified_at_file, indexed_signature, dimensions, duration_seconds, page_count, thumbnail_state, index_state, last_indexed_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [
                .text(asset.id.uuidString), .text(asset.watchedFolderID.uuidString), .text(asset.fileIdentity), .text(asset.pathRelativeToFolder), .text(asset.pathHash), .text(asset.filename), .text(asset.mediaType.rawValue), .text(asset.contentType), .integer(asset.sizeBytes), date(asset.createdAtFile), date(asset.modifiedAtFile), .text(asset.indexedFileSignature), optionalText(asset.dimensions), optionalDouble(asset.durationSeconds), optionalInt(asset.pageCount), .text(asset.thumbnailState.rawValue), .text(asset.indexState.rawValue), date(asset.lastIndexedAt), date(asset.createdAt), date(asset.updatedAt)
            ]
        )
    }

    public func get(id: UUID) async throws -> MediaAsset? {
        try await database.query("SELECT * FROM media_assets WHERE id = ?;", bindings: [.text(id.uuidString)]).first.map(Self.decode)
    }

    public func list(watchedFolderID: UUID?) async throws -> [MediaAsset] {
        if let watchedFolderID {
            return try await database.query("SELECT * FROM media_assets WHERE watched_folder_id = ? ORDER BY filename ASC;", bindings: [.text(watchedFolderID.uuidString)]).map(Self.decode)
        }
        return try await database.query("SELECT * FROM media_assets ORDER BY filename ASC;").map(Self.decode)
    }

    public func updateIndexState(id: UUID, state: IndexState, lastIndexedAt: Date?) async throws {
        try await database.execute("UPDATE media_assets SET index_state = ?, last_indexed_at = ?, updated_at = ? WHERE id = ?;", bindings: [.text(state.rawValue), date(lastIndexedAt), date(Date()), .text(id.uuidString)])
    }

    public func remove(id: UUID) async throws { try await database.execute("DELETE FROM media_assets WHERE id = ?;", bindings: [.text(id.uuidString)]) }
    public func removeByWatchedFolder(id: UUID) async throws { try await database.execute("DELETE FROM media_assets WHERE watched_folder_id = ?;", bindings: [.text(id.uuidString)]) }

    private static func decode(_ row: SQLiteRow) -> MediaAsset {
        MediaAsset(
            id: uuid(row["id"]),
            watchedFolderID: uuid(row["watched_folder_id"]),
            fileIdentity: row["file_identity"].stringValue ?? "",
            pathRelativeToFolder: row["relative_path"].stringValue ?? "",
            pathHash: row["path_hash"].stringValue ?? "",
            filename: row["filename"].stringValue ?? "",
            mediaType: MediaType(rawValue: row["media_type"].stringValue ?? "") ?? .image,
            contentType: row["content_type"].stringValue ?? "",
            sizeBytes: row["size_bytes"].int64Value ?? 0,
            createdAtFile: optionalDate(row["created_at_file"]),
            modifiedAtFile: optionalDate(row["modified_at_file"]),
            indexedFileSignature: row["indexed_signature"].stringValue ?? "",
            dimensions: row["dimensions"].stringValue,
            durationSeconds: row["duration_seconds"].doubleValue,
            pageCount: row["page_count"].intValue,
            thumbnailState: IndexState(rawValue: row["thumbnail_state"].stringValue ?? "") ?? .missing,
            indexState: IndexState(rawValue: row["index_state"].stringValue ?? "") ?? .discovered,
            lastIndexedAt: optionalDate(row["last_indexed_at"]),
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
            updatedAt: optionalDate(row["updated_at"]) ?? Date(timeIntervalSince1970: 0)
        )
    }
}

public actor SQLiteExtractionRecordRepository: ExtractionRecordRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }

    public func save(_ record: ExtractionRecord) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO extraction_records
            (id, asset_id, stage, provider_id, provider_mode, status, safe_summary, confidence, page_number, timestamp_start, timestamp_end, error_category, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [.text(record.id.uuidString), .text(record.assetID.uuidString), .text(record.stage.rawValue), optionalText(record.providerID), .text(record.providerMode.rawValue), .text(record.status.rawValue), optionalText(record.outputSummary), optionalDouble(record.confidence), optionalInt(record.pageNumber), optionalDouble(record.timestampStart), optionalDouble(record.timestampEnd), optionalText(record.errorCategory?.rawValue), date(record.createdAt), date(record.updatedAt)]
        )
    }

    public func list(assetID: UUID) async throws -> [ExtractionRecord] {
        try await database.query("SELECT * FROM extraction_records WHERE asset_id = ? ORDER BY created_at ASC;", bindings: [.text(assetID.uuidString)]).map(Self.decode)
    }

    public func removeByAsset(id: UUID) async throws { try await database.execute("DELETE FROM extraction_records WHERE asset_id = ?;", bindings: [.text(id.uuidString)]) }

    private static func decode(_ row: SQLiteRow) -> ExtractionRecord {
        ExtractionRecord(
            id: uuid(row["id"]),
            assetID: uuid(row["asset_id"]),
            stage: ExtractionStage(rawValue: row["stage"].stringValue ?? "") ?? .metadata,
            providerID: row["provider_id"].stringValue,
            providerMode: ProviderMode(rawValue: row["provider_mode"].stringValue ?? "") ?? .localFramework,
            status: IndexState(rawValue: row["status"].stringValue ?? "") ?? .queued,
            outputSummary: row["safe_summary"].stringValue,
            confidence: row["confidence"].doubleValue,
            pageNumber: row["page_number"].intValue,
            timestampStart: row["timestamp_start"].doubleValue,
            timestampEnd: row["timestamp_end"].doubleValue,
            errorCategory: row["error_category"].stringValue.flatMap(FailureCategory.init(rawValue:)),
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
            updatedAt: optionalDate(row["updated_at"]) ?? Date(timeIntervalSince1970: 0)
        )
    }
}

public actor SQLiteSearchableChunkRepository: SearchableChunkRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }

    public func save(_ chunk: SearchableChunk) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO searchable_chunks
            (id, asset_id, extraction_record_id, chunk_type, text, normalized_text, embedding_model, page_number, timestamp_start, timestamp_end, confidence, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [.text(chunk.id.uuidString), .text(chunk.assetID.uuidString), optionalText(chunk.extractionRecordID?.uuidString), .text(chunk.chunkType.rawValue), .text(chunk.text), .text(chunk.normalizedText), optionalText(chunk.embeddingModel), optionalInt(chunk.pageNumber), optionalDouble(chunk.timestampStart), optionalDouble(chunk.timestampEnd), optionalDouble(chunk.confidence), date(chunk.createdAt)]
        )
        try await database.execute(
            "INSERT OR REPLACE INTO searchable_chunks_fts(id, filename, text, labels, transcript, pdf_text) VALUES (?, ?, ?, ?, ?, ?);",
            bindings: ftsBindings(for: chunk)
        )
        if let embedding = chunk.embedding, let model = chunk.embeddingModel {
            try await database.execute("INSERT OR REPLACE INTO vector_embeddings(chunk_id, model_id, dimensions, vector) VALUES (?, ?, ?, ?);", bindings: [.text(chunk.id.uuidString), .text(model), .integer(Int64(embedding.count)), .data(Self.data(from: embedding))])
        }
    }

    public func list(assetID: UUID) async throws -> [SearchableChunk] {
        try await database.query("SELECT c.*, e.vector AS embedding FROM searchable_chunks c LEFT JOIN vector_embeddings e ON e.chunk_id = c.id WHERE c.asset_id = ? ORDER BY c.created_at ASC;", bindings: [.text(assetID.uuidString)]).map(Self.decode)
    }

    public func searchText(_ query: String, limit: Int) async throws -> [SearchableChunk] {
        let boundedLimit = max(1, min(limit, BuildConfiguration.maxSearchResults))
        let rows = try await database.query(
            """
            SELECT c.* FROM searchable_chunks_fts f
            JOIN searchable_chunks c ON c.id = f.id
            WHERE searchable_chunks_fts MATCH ?
            ORDER BY rank LIMIT ?;
            """,
            bindings: [.text(query), .integer(Int64(boundedLimit))]
        )
        return rows.map(Self.decode)
    }

    public func removeByAsset(id: UUID) async throws {
        let chunks = try await list(assetID: id)
        for chunk in chunks {
            try await database.execute("DELETE FROM searchable_chunks_fts WHERE id = ?;", bindings: [.text(chunk.id.uuidString)])
            try await database.execute("DELETE FROM vector_embeddings WHERE chunk_id = ?;", bindings: [.text(chunk.id.uuidString)])
        }
        try await database.execute("DELETE FROM searchable_chunks WHERE asset_id = ?;", bindings: [.text(id.uuidString)])
    }

    private func ftsBindings(for chunk: SearchableChunk) -> [SQLiteValue] {
        let empty = SQLiteValue.text("")
        switch chunk.chunkType {
        case .filename: return [.text(chunk.id.uuidString), .text(chunk.text), empty, empty, empty, empty]
        case .visibleText: return [.text(chunk.id.uuidString), empty, .text(chunk.text), empty, empty, empty]
        case .visualLabel, .semantic: return [.text(chunk.id.uuidString), empty, empty, .text(chunk.text), empty, empty]
        case .transcript: return [.text(chunk.id.uuidString), empty, empty, empty, .text(chunk.text), empty]
        case .pdfText: return [.text(chunk.id.uuidString), empty, empty, empty, empty, .text(chunk.text)]
        }
    }

    private static func decode(_ row: SQLiteRow) -> SearchableChunk {
        SearchableChunk(
            id: uuid(row["id"]),
            assetID: uuid(row["asset_id"]),
            extractionRecordID: row["extraction_record_id"].stringValue.flatMap(UUID.init(uuidString:)),
            chunkType: MatchReason(rawValue: row["chunk_type"].stringValue ?? "") ?? .visibleText,
            text: row["text"].stringValue ?? "",
            normalizedText: row["normalized_text"].stringValue ?? "",
            embedding: row["embedding"].dataValue.map(floats(from:)),
            embeddingModel: row["embedding_model"].stringValue,
            pageNumber: row["page_number"].intValue,
            timestampStart: row["timestamp_start"].doubleValue,
            timestampEnd: row["timestamp_end"].doubleValue,
            confidence: row["confidence"].doubleValue,
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0)
        )
    }

    private static func data(from floats: [Float]) -> Data {
        var values = floats
        return Data(bytes: &values, count: MemoryLayout<Float>.size * values.count)
    }

    private static func floats(from data: Data) -> [Float] {
        let count = data.count / MemoryLayout<Float>.size
        return data.withUnsafeBytes { buffer in
            guard let base = buffer.bindMemory(to: Float.self).baseAddress else { return [] }
            return Array(UnsafeBufferPointer(start: base, count: count))
        }
    }
}

public actor SQLiteIndexJobRepository: IndexJobRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }

    public func enqueue(_ job: IndexJob) async throws { try await save(job) }
    public func update(_ job: IndexJob) async throws { try await save(job) }

    public func nextRunnableJob() async throws -> IndexJob? {
        try await database.query("SELECT * FROM index_jobs WHERE status = ? ORDER BY priority DESC, created_at ASC LIMIT 1;", bindings: [.text(IndexState.queued.rawValue)]).first.map(Self.decode)
    }

    public func get(id: UUID) async throws -> IndexJob? {
        try await database.query("SELECT * FROM index_jobs WHERE id = ?;", bindings: [.text(id.uuidString)]).first.map(Self.decode)
    }

    public func list(status: IndexState?) async throws -> [IndexJob] {
        if let status {
            return try await database.query("SELECT * FROM index_jobs WHERE status = ? ORDER BY priority DESC, created_at ASC;", bindings: [.text(status.rawValue)]).map(Self.decode)
        }
        return try await database.query("SELECT * FROM index_jobs ORDER BY created_at ASC;").map(Self.decode)
    }

    public func remove(id: UUID) async throws { try await database.execute("DELETE FROM index_jobs WHERE id = ?;", bindings: [.text(id.uuidString)]) }

    private func save(_ job: IndexJob) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO index_jobs
            (id, job_type, watched_folder_id, asset_id, priority, status, attempt_count, last_error_category, progress_unit, progress_completed, progress_total, created_at, started_at, completed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [.text(job.id.uuidString), .text(job.jobType.rawValue), optionalText(job.watchedFolderID?.uuidString), optionalText(job.assetID?.uuidString), .integer(Int64(job.priority)), .text(job.status.rawValue), .integer(Int64(job.attemptCount)), optionalText(job.lastErrorCategory?.rawValue), optionalText(job.progressUnit), .integer(Int64(job.progressCompleted)), optionalInt(job.progressTotal), date(job.createdAt), date(job.startedAt), date(job.completedAt)]
        )
    }

    private static func decode(_ row: SQLiteRow) -> IndexJob {
        IndexJob(
            id: uuid(row["id"]),
            jobType: JobType(rawValue: row["job_type"].stringValue ?? "") ?? .indexAsset,
            watchedFolderID: row["watched_folder_id"].stringValue.flatMap(UUID.init(uuidString:)),
            assetID: row["asset_id"].stringValue.flatMap(UUID.init(uuidString:)),
            priority: row["priority"].intValue ?? 0,
            status: IndexState(rawValue: row["status"].stringValue ?? "") ?? .queued,
            attemptCount: row["attempt_count"].intValue ?? 0,
            lastErrorCategory: row["last_error_category"].stringValue.flatMap(FailureCategory.init(rawValue:)),
            progressUnit: row["progress_unit"].stringValue,
            progressCompleted: row["progress_completed"].intValue ?? 0,
            progressTotal: row["progress_total"].intValue,
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
            startedAt: optionalDate(row["started_at"]),
            completedAt: optionalDate(row["completed_at"])
        )
    }
}

public actor SQLiteIndexFailureRepository: IndexFailureRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }

    public func save(_ failure: IndexFailure) async throws {
        try await database.execute(
            """
            INSERT OR REPLACE INTO index_failures
            (id, asset_id, watched_folder_id, stage, category, retryability, safe_message, raw_debug_reference, created_at, resolved_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [.text(failure.id.uuidString), optionalText(failure.assetID?.uuidString), optionalText(failure.watchedFolderID?.uuidString), .text(failure.stage), .text(failure.category.rawValue), .text(failure.retryability.rawValue), .text(failure.safeMessage), optionalText(failure.rawDebugReference), date(failure.createdAt), date(failure.resolvedAt)]
        )
    }

    public func get(id: UUID) async throws -> IndexFailure? { try await database.query("SELECT * FROM index_failures WHERE id = ?;", bindings: [.text(id.uuidString)]).first.map(Self.decode) }
    public func unresolved() async throws -> [IndexFailure] { try await database.query("SELECT * FROM index_failures WHERE resolved_at IS NULL ORDER BY created_at DESC;").map(Self.decode) }
    public func resolve(id: UUID, at resolvedAt: Date) async throws { try await database.execute("UPDATE index_failures SET resolved_at = ? WHERE id = ?;", bindings: [date(resolvedAt), .text(id.uuidString)]) }

    private static func decode(_ row: SQLiteRow) -> IndexFailure {
        IndexFailure(
            id: uuid(row["id"]),
            assetID: row["asset_id"].stringValue.flatMap(UUID.init(uuidString:)),
            watchedFolderID: row["watched_folder_id"].stringValue.flatMap(UUID.init(uuidString:)),
            stage: row["stage"].stringValue ?? "",
            category: FailureCategory(rawValue: row["category"].stringValue ?? "") ?? .unknownRedacted,
            retryability: Retryability(rawValue: row["retryability"].stringValue ?? "") ?? .notRetryable,
            safeMessage: row["safe_message"].stringValue ?? "",
            rawDebugReference: row["raw_debug_reference"].stringValue,
            createdAt: optionalDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
            resolvedAt: optionalDate(row["resolved_at"])
        )
    }
}

public actor SQLiteProviderSettingsRepository: ProviderSettingsRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }

    public func save(_ setting: ProviderSetting) async throws {
        let modelsData = try JSONEncoder().encode(setting.modelIDs)
        let models = String(data: modelsData, encoding: .utf8) ?? "[]"
        try await database.execute(
            """
            INSERT OR REPLACE INTO provider_settings
            (id, display_name, base_url, is_enabled, automatic_indexing_enabled, locality, transport_state, credential_state, model_ids_json, last_health_check_at, last_health_status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [.text(setting.id), .text(setting.displayName), .text(setting.baseURL.absoluteString), .integer(setting.isEnabled ? 1 : 0), .integer(setting.automaticIndexingEnabled ? 1 : 0), .text(setting.locality.rawValue), .text(setting.transportState.rawValue), .text(setting.credentialState.rawValue), .text(models), date(setting.lastHealthCheckAt), .text(setting.lastHealthStatus.rawValue)]
        )
    }

    public func get(id: String) async throws -> ProviderSetting? { try await database.query("SELECT * FROM provider_settings WHERE id = ?;", bindings: [.text(id)]).first.map(Self.decode) }
    public func list() async throws -> [ProviderSetting] { try await database.query("SELECT * FROM provider_settings ORDER BY id ASC;").map(Self.decode) }
    public func remove(id: String) async throws { try await database.execute("DELETE FROM provider_settings WHERE id = ?;", bindings: [.text(id)]) }

    private static func decode(_ row: SQLiteRow) -> ProviderSetting {
        let modelsJSON = row["model_ids_json"].stringValue?.data(using: .utf8) ?? Data()
        let models = (try? JSONDecoder().decode([String].self, from: modelsJSON)) ?? []
        return ProviderSetting(
            id: row["id"].stringValue ?? "",
            displayName: row["display_name"].stringValue ?? "",
            baseURL: URL(string: row["base_url"].stringValue ?? "") ?? BuildConfiguration.omlxBaseURL,
            isEnabled: bool(row["is_enabled"]),
            automaticIndexingEnabled: bool(row["automatic_indexing_enabled"]),
            locality: ProviderLocality(rawValue: row["locality"].stringValue ?? "") ?? .remote,
            transportState: TransportState(rawValue: row["transport_state"].stringValue ?? "") ?? .invalidURL,
            credentialState: CredentialState(rawValue: row["credential_state"].stringValue ?? "") ?? .noneNeeded,
            modelIDs: models,
            lastHealthCheckAt: optionalDate(row["last_health_check_at"]),
            lastHealthStatus: ProviderHealthStatus(rawValue: row["last_health_status"].stringValue ?? "") ?? .unknown
        )
    }
}

public actor SQLiteAppSettingsRepository: AppSettingsRepository {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }
    public func set(_ value: String, forKey key: String) async throws { try await database.execute("INSERT OR REPLACE INTO app_settings(key, value, updated_at) VALUES (?, ?, ?);", bindings: [.text(key), .text(value), date(Date())]) }
    public func value(forKey key: String) async throws -> String? { try await database.query("SELECT value FROM app_settings WHERE key = ?;", bindings: [.text(key)]).first?["value"].stringValue }
    public func removeValue(forKey key: String) async throws { try await database.execute("DELETE FROM app_settings WHERE key = ?;", bindings: [.text(key)]) }
}

public actor StorageMaintenanceRepository: StorageMaintenanceRepositoryProtocol {
    private let database: LocalLensDatabase
    public init(database: LocalLensDatabase) { self.database = database }
    public func indexedAssetCount() async throws -> Int { try await database.scalarInt("SELECT COUNT(*) AS count FROM media_assets;") }
    public func deleteIndexData() async throws {
        try await database.execute("DELETE FROM searchable_chunks_fts;")
        try await database.execute("DELETE FROM searchable_chunks;")
        try await database.execute("DELETE FROM vector_embeddings;")
        try await database.execute("DELETE FROM extraction_records;")
        try await database.execute("DELETE FROM media_assets;")
        try await database.execute("DELETE FROM index_failures;")
        try await database.execute("DELETE FROM index_jobs;")
    }
}


private func date(_ date: Date?) -> SQLiteValue { date.map { .real($0.timeIntervalSince1970) } ?? .null }
private func optionalDate(_ value: SQLiteValue) -> Date? { value.doubleValue.map(Date.init(timeIntervalSince1970:)) }
private func optionalText(_ value: String?) -> SQLiteValue { value.map(SQLiteValue.text) ?? .null }
private func optionalDouble(_ value: Double?) -> SQLiteValue { value.map(SQLiteValue.real) ?? .null }
private func optionalInt(_ value: Int?) -> SQLiteValue { value.map { .integer(Int64($0)) } ?? .null }
private func uuid(_ value: SQLiteValue) -> UUID { value.stringValue.flatMap(UUID.init(uuidString:)) ?? UUID() }
private func bool(_ value: SQLiteValue) -> Bool { (value.intValue ?? 0) != 0 }
