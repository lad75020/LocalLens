import Foundation

public struct WatchedFolder: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var displayName: String
    public var bookmarkData: Data
    public var originalPathHash: String
    public var displayPath: String
    public var isEnabled: Bool
    public var authorizationState: AuthorizationState
    public var lastScanStartedAt: Date?
    public var lastScanCompletedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), displayName: String, bookmarkData: Data, originalPathHash: String, displayPath: String, isEnabled: Bool = true, authorizationState: AuthorizationState = .authorized, lastScanStartedAt: Date? = nil, lastScanCompletedAt: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.displayName = displayName; self.bookmarkData = bookmarkData; self.originalPathHash = originalPathHash; self.displayPath = displayPath; self.isEnabled = isEnabled; self.authorizationState = authorizationState; self.lastScanStartedAt = lastScanStartedAt; self.lastScanCompletedAt = lastScanCompletedAt; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct MediaAsset: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var watchedFolderID: UUID
    public var fileIdentity: String
    public var pathRelativeToFolder: String
    public var pathHash: String
    public var filename: String
    public var mediaType: MediaType
    public var contentType: String
    public var sizeBytes: Int64
    public var createdAtFile: Date?
    public var modifiedAtFile: Date?
    public var indexedFileSignature: String
    public var dimensions: String?
    public var durationSeconds: Double?
    public var pageCount: Int?
    public var thumbnailState: IndexState
    public var indexState: IndexState
    public var lastIndexedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
}

public struct ExtractionRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var assetID: UUID
    public var stage: ExtractionStage
    public var providerID: String?
    public var providerMode: ProviderMode
    public var status: IndexState
    public var outputSummary: String?
    public var confidence: Double?
    public var pageNumber: Int?
    public var timestampStart: Double?
    public var timestampEnd: Double?
    public var errorCategory: FailureCategory?
    public var createdAt: Date
    public var updatedAt: Date
}

public struct SearchableChunk: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var assetID: UUID
    public var extractionRecordID: UUID?
    public var chunkType: MatchReason
    public var text: String
    public var normalizedText: String
    public var embedding: [Float]?
    public var embeddingModel: String?
    public var pageNumber: Int?
    public var timestampStart: Double?
    public var timestampEnd: Double?
    public var confidence: Double?
    public var createdAt: Date
}

public struct IndexJob: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var jobType: JobType
    public var watchedFolderID: UUID?
    public var assetID: UUID?
    public var priority: Int
    public var status: IndexState
    public var attemptCount: Int
    public var lastErrorCategory: FailureCategory?
    public var progressUnit: String?
    public var progressCompleted: Int
    public var progressTotal: Int?
    public var createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?

    public init(id: UUID = UUID(), jobType: JobType, watchedFolderID: UUID? = nil, assetID: UUID? = nil, priority: Int = 0, status: IndexState = .queued, attemptCount: Int = 0, lastErrorCategory: FailureCategory? = nil, progressUnit: String? = nil, progressCompleted: Int = 0, progressTotal: Int? = nil, createdAt: Date = Date(), startedAt: Date? = nil, completedAt: Date? = nil) {
        self.id = id; self.jobType = jobType; self.watchedFolderID = watchedFolderID; self.assetID = assetID; self.priority = priority; self.status = status; self.attemptCount = attemptCount; self.lastErrorCategory = lastErrorCategory; self.progressUnit = progressUnit; self.progressCompleted = progressCompleted; self.progressTotal = progressTotal; self.createdAt = createdAt; self.startedAt = startedAt; self.completedAt = completedAt
    }
}

public struct IndexFailure: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var assetID: UUID?
    public var watchedFolderID: UUID?
    public var stage: String
    public var category: FailureCategory
    public var retryability: Retryability
    public var safeMessage: String
    public var rawDebugReference: String?
    public var createdAt: Date
    public var resolvedAt: Date?
}

public struct ProviderSetting: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var baseURL: URL
    public var isEnabled: Bool
    public var automaticIndexingEnabled: Bool
    public var locality: ProviderLocality
    public var transportState: TransportState
    public var credentialState: CredentialState
    public var modelIDs: [String]
    public var selectedModelID: String? = nil
    public var lastHealthCheckAt: Date?
    public var lastHealthStatus: ProviderHealthStatus

    public var effectiveModelID: String? { selectedModelID ?? modelIDs.first }
    public var hasUsableSelectedModel: Bool { selectedModelID.map { modelIDs.contains($0) } ?? false }
}


public struct OfficeIndexingPreferences: Codable, Equatable, Sendable {
    public var pptxEnabled: Bool
    public var docxEnabled: Bool
    public var xlsxEnabled: Bool

    public init(pptxEnabled: Bool = false, docxEnabled: Bool = false, xlsxEnabled: Bool = false) {
        self.pptxEnabled = pptxEnabled
        self.docxEnabled = docxEnabled
        self.xlsxEnabled = xlsxEnabled
    }

    public func isEnabled(for kind: OfficeDocumentKind) -> Bool {
        switch kind {
        case .pptx: return pptxEnabled
        case .docx: return docxEnabled
        case .xlsx: return xlsxEnabled
        }
    }
}

public struct ProviderModelSelectionState: Codable, Equatable, Sendable {
    public var providerID: String
    public var selectedModelID: String?
    public var availableModelIDs: [String]
    public var availabilityState: ProviderSelectionAvailability
    public var lastRefreshedAt: Date?
    public var lastSafeError: String?

    public init(providerID: String, selectedModelID: String? = nil, availableModelIDs: [String] = [], availabilityState: ProviderSelectionAvailability = .unknown, lastRefreshedAt: Date? = nil, lastSafeError: String? = nil) {
        self.providerID = providerID
        self.selectedModelID = selectedModelID
        self.availableModelIDs = availableModelIDs
        self.availabilityState = availabilityState
        self.lastRefreshedAt = lastRefreshedAt
        self.lastSafeError = lastSafeError
    }
}

public struct HermesProfileSummary: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var isDefault: Bool
    public var model: String?
    public var provider: String?

    public init(id: String, displayName: String, isDefault: Bool = false, model: String? = nil, provider: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.isDefault = isDefault
        self.model = model
        self.provider = provider
    }
}

public struct HermesProfileSelectionState: Codable, Equatable, Sendable {
    public var selectedProfileID: String?
    public var selectedProfileDisplayName: String?
    public var availableProfiles: [HermesProfileSummary]
    public var availabilityState: ProviderSelectionAvailability
    public var lastRefreshedAt: Date?
    public var lastSafeError: String?

    public init(selectedProfileID: String? = nil, selectedProfileDisplayName: String? = nil, availableProfiles: [HermesProfileSummary] = [], availabilityState: ProviderSelectionAvailability = .unknown, lastRefreshedAt: Date? = nil, lastSafeError: String? = nil) {
        self.selectedProfileID = selectedProfileID
        self.selectedProfileDisplayName = selectedProfileDisplayName
        self.availableProfiles = availableProfiles
        self.availabilityState = availabilityState
        self.lastRefreshedAt = lastRefreshedAt
        self.lastSafeError = lastSafeError
    }

    public var isReadyForOfficeIndexing: Bool {
        guard let selectedProfileID else { return false }
        return availabilityState == .available && availableProfiles.contains { $0.id == selectedProfileID }
    }
}

public struct OfficeExtractionMetadata: Codable, Equatable, Sendable {
    public var assetID: UUID
    public var officeKind: OfficeDocumentKind
    public var providerID: String
    public var hermesProfileID: String
    public var safeSummary: String?
    public var safeSnippet: String?
    public var createdAt: Date

    public init(assetID: UUID, officeKind: OfficeDocumentKind, providerID: String, hermesProfileID: String, safeSummary: String? = nil, safeSnippet: String? = nil, createdAt: Date = Date()) {
        self.assetID = assetID
        self.officeKind = officeKind
        self.providerID = providerID
        self.hermesProfileID = hermesProfileID
        self.safeSummary = safeSummary
        self.safeSnippet = safeSnippet
        self.createdAt = createdAt
    }
}

public struct SearchRequest: Equatable, Sendable {
    public var query: String
    public var mediaTypes: Set<MediaType>
    public var watchedFolderIDs: Set<UUID>
    public var limit: Int
    public var includeMissing: Bool

    public init(query: String, mediaTypes: Set<MediaType> = [], watchedFolderIDs: Set<UUID> = [], limit: Int = 25, includeMissing: Bool = false) {
        self.query = query
        self.mediaTypes = mediaTypes
        self.watchedFolderIDs = watchedFolderIDs
        self.limit = max(1, min(limit, BuildConfiguration.maxSearchResults))
        self.includeMissing = includeMissing
    }

    public var normalizedQuery: String {
        query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isEmpty: Bool { normalizedQuery.isEmpty }
    public var boundedProviderQuery: String { String(normalizedQuery.prefix(BuildConfiguration.maxProviderQueryCharacters)) }
    public var diagnosticsSummary: String { "SearchRequest(query: [REDACTED], mediaTypes: \(mediaTypes.count), watchedFolders: \(watchedFolderIDs.count), limit: \(limit), includeMissing: \(includeMissing))" }
}

public struct SearchResultDTO: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let assetID: UUID
    public let filename: String
    public let mediaType: MediaType
    public let folderContext: String
    public let thumbnailID: UUID?
    public let score: Double
    public let matchReasons: [MatchReason]
    public let snippet: String?
    public let pageNumber: Int?
    public let timestampStart: Double?
    public let timestampEnd: Double?
    public let durationSeconds: Double?
    public let isMissing: Bool

    public init(id: UUID = UUID(), assetID: UUID, filename: String, mediaType: MediaType, folderContext: String, thumbnailID: UUID?, score: Double, matchReasons: [MatchReason], snippet: String?, pageNumber: Int?, timestampStart: Double?, timestampEnd: Double?, durationSeconds: Double? = nil, isMissing: Bool) {
        self.id = id
        self.assetID = assetID
        self.filename = filename
        self.mediaType = mediaType
        self.folderContext = folderContext
        self.thumbnailID = thumbnailID
        self.score = score
        self.matchReasons = matchReasons
        self.snippet = snippet
        self.pageNumber = pageNumber
        self.timestampStart = timestampStart
        self.timestampEnd = timestampEnd
        self.durationSeconds = durationSeconds
        self.isMissing = isMissing
    }
}
