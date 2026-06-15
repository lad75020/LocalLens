import Foundation

public struct OfficeDiscoveryPolicy: Equatable, Sendable {
    public var pptxEnabled: Bool
    public var docxEnabled: Bool
    public var xlsxEnabled: Bool
    public var hermesReadyForOfficeIndexing: Bool

    public init(pptxEnabled: Bool = false, docxEnabled: Bool = false, xlsxEnabled: Bool = false, hermesReadyForOfficeIndexing: Bool = false) {
        self.pptxEnabled = pptxEnabled
        self.docxEnabled = docxEnabled
        self.xlsxEnabled = xlsxEnabled
        self.hermesReadyForOfficeIndexing = hermesReadyForOfficeIndexing
    }

    public init(preferences: OfficeIndexingPreferences, hermesReadyForOfficeIndexing: Bool) {
        self.init(pptxEnabled: preferences.pptxEnabled, docxEnabled: preferences.docxEnabled, xlsxEnabled: preferences.xlsxEnabled, hermesReadyForOfficeIndexing: hermesReadyForOfficeIndexing)
    }

    public func allows(_ kind: OfficeDocumentKind) -> Bool {
        guard hermesReadyForOfficeIndexing else { return false }
        switch kind {
        case .pptx: return pptxEnabled
        case .docx: return docxEnabled
        case .xlsx: return xlsxEnabled
        }
    }
}

public struct MediaDiscoveryResult: Equatable, Sendable {
    public let assets: [MediaAsset]
    public let jobs: [IndexJob]
    public let unsupportedFileCount: Int
    public let skippedFileCount: Int

    public init(assets: [MediaAsset], jobs: [IndexJob], unsupportedFileCount: Int, skippedFileCount: Int) {
        self.assets = assets
        self.jobs = jobs
        self.unsupportedFileCount = unsupportedFileCount
        self.skippedFileCount = skippedFileCount
    }
}

public struct MediaDiscoveryService: Sendable {
    public let resolver: MediaTypeResolver
    public let identityService: FileIdentityService

    public init(resolver: MediaTypeResolver = MediaTypeResolver(), identityService: FileIdentityService = FileIdentityService()) {
        self.resolver = resolver
        self.identityService = identityService
    }

    public func supportedFiles(in folder: URL, officePolicy: OfficeDiscoveryPolicy = OfficeDiscoveryPolicy()) -> [URL] {
        (try? discover(in: folder, watchedFolderID: UUID(), officePolicy: officePolicy).assets.map { folder.appendingPathComponent($0.pathRelativeToFolder) }) ?? []
    }

    public func discover(in folder: URL, watchedFolderID: UUID, officePolicy: OfficeDiscoveryPolicy = OfficeDiscoveryPolicy()) throws -> MediaDiscoveryResult {
        let root = folder.standardizedFileURL
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .isDirectoryKey,
            .isHiddenKey,
            .isPackageKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .fileResourceIdentifierKey
        ]
        var assets: [MediaAsset] = []
        var unsupported = 0
        var skipped = 0

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return MediaDiscoveryResult(assets: [], jobs: [Self.discoverFolderJob(watchedFolderID: watchedFolderID)], unsupportedFileCount: 0, skippedFileCount: 1)
        }

        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: Set(keys))
            if values?.isHidden == true || values?.isPackage == true || values?.isSymbolicLink == true {
                skipped += 1
                if values?.isDirectory == true { enumerator.skipDescendants() }
                continue
            }
            if values?.isDirectory == true { continue }
            guard values?.isRegularFile ?? FileManager.default.fileExists(atPath: fileURL.path) else {
                skipped += 1
                continue
            }
            guard let resolved = resolver.resolve(fileURL) else {
                unsupported += 1
                continue
            }
            if resolved.mediaType == .office {
                guard let kind = resolver.officeKind(for: fileURL), officePolicy.allows(kind) else {
                    unsupported += 1
                    continue
                }
            }
            do {
                let identity = try identityService.identity(for: fileURL)
                let now = Date()
                assets.append(MediaAsset(
                    id: UUID(),
                    watchedFolderID: watchedFolderID,
                    fileIdentity: identity.fileIdentity,
                    pathRelativeToFolder: relativePath(from: root, to: fileURL),
                    pathHash: identity.pathHash,
                    filename: fileURL.lastPathComponent,
                    mediaType: resolved.mediaType,
                    contentType: resolved.contentTypeIdentifier,
                    sizeBytes: identity.sizeBytes,
                    createdAtFile: identity.createdAtFile,
                    modifiedAtFile: identity.modifiedAtFile,
                    indexedFileSignature: identity.signature,
                    dimensions: nil,
                    durationSeconds: nil,
                    pageCount: nil,
                    thumbnailState: .missing,
                    indexState: .discovered,
                    lastIndexedAt: nil,
                    createdAt: now,
                    updatedAt: now
                ))
            } catch {
                skipped += 1
            }
        }

        let assetJobs = assets.map {
            IndexJob(jobType: .indexAsset, watchedFolderID: watchedFolderID, assetID: $0.id, priority: 0, status: .queued, progressUnit: "stages")
        }
        return MediaDiscoveryResult(
            assets: assets.sorted { $0.pathRelativeToFolder < $1.pathRelativeToFolder },
            jobs: [Self.discoverFolderJob(watchedFolderID: watchedFolderID)] + assetJobs,
            unsupportedFileCount: unsupported,
            skippedFileCount: skipped
        )
    }

    private static func discoverFolderJob(watchedFolderID: UUID) -> IndexJob {
        IndexJob(jobType: .discoverFolder, watchedFolderID: watchedFolderID, priority: 10, status: .queued, progressUnit: "files")
    }

    private func relativePath(from root: URL, to file: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let filePath = file.standardizedFileURL.path
        if filePath.hasPrefix(rootPath + "/") {
            return String(filePath.dropFirst(rootPath.count + 1))
        }
        return file.lastPathComponent
    }
}
