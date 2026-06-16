import Foundation

public protocol WatchedFolderRepository: Sendable {
    func save(_ folder: WatchedFolder) async throws
    func get(id: UUID) async throws -> WatchedFolder?
    func list() async throws -> [WatchedFolder]
    func updateAuthorizationState(id: UUID, state: AuthorizationState) async throws
    func remove(id: UUID) async throws
}

public protocol MediaAssetRepository: Sendable {
    func save(_ asset: MediaAsset) async throws
    func get(id: UUID) async throws -> MediaAsset?
    func list(watchedFolderID: UUID?) async throws -> [MediaAsset]
    func updateIndexState(id: UUID, state: IndexState, lastIndexedAt: Date?) async throws
    func remove(id: UUID) async throws
    func removeByWatchedFolder(id: UUID) async throws
}

public protocol ExtractionRecordRepository: Sendable {
    func save(_ record: ExtractionRecord) async throws
    func list(assetID: UUID) async throws -> [ExtractionRecord]
    func removeByAsset(id: UUID) async throws
}

public protocol SearchableChunkRepository: Sendable {
    func save(_ chunk: SearchableChunk) async throws
    func list(assetID: UUID) async throws -> [SearchableChunk]
    func searchText(_ query: String, limit: Int) async throws -> [SearchableChunk]
    func removeByAsset(id: UUID) async throws
}

public protocol IndexJobRepository: Sendable {
    func enqueue(_ job: IndexJob) async throws
    func nextRunnableJob() async throws -> IndexJob?
    func get(id: UUID) async throws -> IndexJob?
    func list(status: IndexState?) async throws -> [IndexJob]
    func update(_ job: IndexJob) async throws
    func remove(id: UUID) async throws
}

public protocol IndexFailureRepository: Sendable {
    func save(_ failure: IndexFailure) async throws
    func get(id: UUID) async throws -> IndexFailure?
    func unresolved() async throws -> [IndexFailure]
    func resolve(id: UUID, at date: Date) async throws
}

public protocol ProviderSettingsRepository: Sendable {
    func save(_ setting: ProviderSetting) async throws
    func get(id: String) async throws -> ProviderSetting?
    func list() async throws -> [ProviderSetting]
    func remove(id: String) async throws
}

public protocol AppSettingsRepository: Sendable {
    func set(_ value: String, forKey key: String) async throws
    func value(forKey key: String) async throws -> String?
    func removeValue(forKey key: String) async throws
}

public protocol OfficePreferencesRepository: Sendable {
    func load() async throws -> OfficeIndexingPreferences
    func save(_ preferences: OfficeIndexingPreferences) async throws
}

public protocol ProviderModelSelectionRepository: Sendable {
    func save(_ state: ProviderModelSelectionState) async throws
    func get(providerID: String) async throws -> ProviderModelSelectionState?
    func list() async throws -> [ProviderModelSelectionState]
}

public protocol HermesProfileSelectionRepository: Sendable {
    func load() async throws -> HermesProfileSelectionState
    func save(_ state: HermesProfileSelectionState) async throws
}

public protocol OfficeExtractionMetadataRepository: Sendable {
    func save(_ metadata: OfficeExtractionMetadata) async throws
    func list(assetID: UUID) async throws -> [OfficeExtractionMetadata]
}


public protocol GeneratedContentRepository: Sendable {
    func save(_ record: GeneratedContentRecord) async throws
    func list(assetID: UUID) async throws -> [GeneratedContentRecord]
    func removeByAsset(id: UUID) async throws
}

public protocol StorageMaintenanceRepositoryProtocol: Sendable {
    func indexedAssetCount() async throws -> Int
    func storageUsage() async throws -> StorageUsageSnapshot
    func deleteIndexData() async throws
    func rebuildIndexData() async throws
    func cleanupCacheData() async throws
}

public struct StorageRepositories: Sendable {
    public let watchedFolders: any WatchedFolderRepository
    public let assets: any MediaAssetRepository
    public let extractionRecords: any ExtractionRecordRepository
    public let chunks: any SearchableChunkRepository
    public let jobs: any IndexJobRepository
    public let failures: any IndexFailureRepository
    public let providers: any ProviderSettingsRepository
    public let appSettings: any AppSettingsRepository
    public let officePreferences: any OfficePreferencesRepository
    public let providerModelSelections: any ProviderModelSelectionRepository
    public let hermesProfileSelection: any HermesProfileSelectionRepository
    public let officeExtractionMetadata: any OfficeExtractionMetadataRepository
    public let generatedContent: (any GeneratedContentRepository)?
    public let maintenance: any StorageMaintenanceRepositoryProtocol

    public init(
        watchedFolders: any WatchedFolderRepository,
        assets: any MediaAssetRepository,
        extractionRecords: any ExtractionRecordRepository,
        chunks: any SearchableChunkRepository,
        jobs: any IndexJobRepository,
        failures: any IndexFailureRepository,
        providers: any ProviderSettingsRepository,
        appSettings: any AppSettingsRepository,
        officePreferences: any OfficePreferencesRepository,
        providerModelSelections: any ProviderModelSelectionRepository,
        hermesProfileSelection: any HermesProfileSelectionRepository,
        officeExtractionMetadata: any OfficeExtractionMetadataRepository,
        generatedContent: (any GeneratedContentRepository)? = nil,
        maintenance: any StorageMaintenanceRepositoryProtocol
    ) {
        self.watchedFolders = watchedFolders
        self.assets = assets
        self.extractionRecords = extractionRecords
        self.chunks = chunks
        self.jobs = jobs
        self.failures = failures
        self.providers = providers
        self.appSettings = appSettings
        self.officePreferences = officePreferences
        self.providerModelSelections = providerModelSelections
        self.hermesProfileSelection = hermesProfileSelection
        self.officeExtractionMetadata = officeExtractionMetadata
        self.generatedContent = generatedContent
        self.maintenance = maintenance
    }
}
