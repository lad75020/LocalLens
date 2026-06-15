import Foundation

@MainActor
public final class DependencyContainer: ObservableObject {
    public let database: LocalLensDatabase
    public let cachePaths: CachePaths
    public let storage: StorageRepositories

    public let redactionPolicy: RedactionPolicy
    public let credentialStore: ProviderCredentialStore
    public let transportPolicy: ProviderTransportPolicy
    public let providerRegistry: ProviderRegistry

    public let thumbnailService: ThumbnailService
    public let imageExtractor: ImageExtractor
    public let pdfExtractor: PDFExtractor
    public let audioTranscriptExtractor: AudioTranscriptExtractor
    public let videoSceneExtractor: VideoSceneExtractor
    public let chunkBuilder: SearchableChunkBuilder
    public let embeddingStageService: EmbeddingStageService

    public let indexCancellation: IndexCancellation
    public let progressSink: ProgressSink
    public let indexQueue: IndexQueueActor
    public let indexProgressStore: IndexProgressStore
    public let indexCoordinator: IndexCoordinator

    public let semanticVectorStore: SemanticVectorStore
    public let snippetBuilder: SnippetBuilder
    public let searchRanker: SearchRanker
    public let searchService: SearchService
    public let searchResultViewModel: SearchResultViewModel

    public let bookmarkStore: SecurityScopedBookmarkStore
    public let folderAuthorizationService: FolderAuthorizationService
    public let mediaTypeResolver: MediaTypeResolver
    public let fileIdentityService: FileIdentityService
    public let mediaDiscoveryService: MediaDiscoveryService
    public let watchedFolderViewModel: WatchedFolderViewModel

    public let quickLookPreviewService: QuickLookPreviewService
    public let finderRevealService: FinderRevealService
    public let clipboardActionService: ClipboardActionService
    public let diagnosticExporter: DiagnosticExporter
    public let privacyAudit: PrivacyAudit
    public let settingsWindowPresenter: SettingsWindowPresenter

    public init() throws {
        let database = try LocalLensDatabase()
        self.database = database
        self.cachePaths = CachePaths(root: database.cacheRootURL)
        try cachePaths.ensureDirectories()

        let watchedFolders = SQLiteWatchedFolderRepository(database: database)
        let assets = SQLiteMediaAssetRepository(database: database)
        let extractionRecords = SQLiteExtractionRecordRepository(database: database)
        let chunks = SQLiteSearchableChunkRepository(database: database)
        let jobs = SQLiteIndexJobRepository(database: database)
        let failures = SQLiteIndexFailureRepository(database: database)
        let providers = SQLiteProviderSettingsRepository(database: database)
        let appSettings = SQLiteAppSettingsRepository(database: database)
        let maintenance = StorageMaintenanceRepository(database: database)
        self.storage = StorageRepositories(
            watchedFolders: watchedFolders,
            assets: assets,
            extractionRecords: extractionRecords,
            chunks: chunks,
            jobs: jobs,
            failures: failures,
            providers: providers,
            appSettings: appSettings,
            maintenance: maintenance
        )

        self.redactionPolicy = RedactionPolicy()
        self.credentialStore = ProviderCredentialStore()
        self.transportPolicy = ProviderTransportPolicy()
        self.providerRegistry = ProviderRegistry(policy: transportPolicy)

        self.thumbnailService = ThumbnailService()
        self.imageExtractor = ImageExtractor()
        self.pdfExtractor = PDFExtractor()
        self.audioTranscriptExtractor = AudioTranscriptExtractor()
        self.videoSceneExtractor = VideoSceneExtractor()
        self.chunkBuilder = SearchableChunkBuilder()
        self.embeddingStageService = EmbeddingStageService()

        self.indexCancellation = IndexCancellation()
        self.progressSink = ProgressSink()
        self.indexQueue = IndexQueueActor()
        self.indexProgressStore = IndexProgressStore()
        self.indexCoordinator = IndexCoordinator()

        self.semanticVectorStore = SemanticVectorStore()
        self.snippetBuilder = SnippetBuilder()
        self.searchRanker = SearchRanker()
        self.searchService = SearchService()
        self.searchResultViewModel = SearchResultViewModel()

        self.bookmarkStore = SecurityScopedBookmarkStore()
        self.folderAuthorizationService = FolderAuthorizationService(bookmarkStore: bookmarkStore)
        self.mediaTypeResolver = MediaTypeResolver()
        self.fileIdentityService = FileIdentityService()
        self.mediaDiscoveryService = MediaDiscoveryService(resolver: mediaTypeResolver, identityService: fileIdentityService)
        self.watchedFolderViewModel = WatchedFolderViewModel()

        self.quickLookPreviewService = QuickLookPreviewService()
        self.finderRevealService = FinderRevealService()
        self.clipboardActionService = ClipboardActionService()
        self.diagnosticExporter = DiagnosticExporter()
        self.privacyAudit = PrivacyAudit()
        self.settingsWindowPresenter = SettingsWindowPresenter()

        Task { [database, providerRegistry, providers] in
            try await database.migrate()
            for setting in providerRegistry.defaultProviders() {
                try await providers.save(setting)
            }
        }
    }
}
