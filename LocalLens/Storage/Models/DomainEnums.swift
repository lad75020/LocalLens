import Foundation

public enum MediaType: String, Codable, CaseIterable, Sendable, Hashable { case image, pdf, audio, video }
public enum IndexState: String, Codable, CaseIterable, Sendable { case discovered, queued, indexing, partial, complete, failed, cancelled, missing, stale }
public enum JobType: String, Codable, CaseIterable, Sendable { case discoverFolder, indexAsset, extractThumbnail, extractText, transcribe, sampleVideo, embedChunks, reindexAsset, reindexFolder, cleanupMissing }
public enum ExtractionStage: String, Codable, CaseIterable, Sendable { case thumbnail, metadata, imageOCR, imageLabels, pdfText, pdfOCR, audioTranscript, videoTranscript, videoKeyframe, sceneLabels, embeddings }
public enum MatchReason: String, Codable, CaseIterable, Sendable, Hashable { case filename, visibleText, pdfText, transcript, visualLabel, semantic }
public enum AuthorizationState: String, Codable, CaseIterable, Sendable { case authorized, staleBookmark, denied, missing, externalUnavailable, needsReauthorization }
public enum ProviderLocality: String, Codable, CaseIterable, Sendable { case localLoopback, localNetwork, remote }
public enum TransportState: String, Codable, CaseIterable, Sendable { case allowedLoopbackHTTP, requiresHTTPS, blockedHTTP, invalidURL }
public enum FailureCategory: String, Codable, CaseIterable, Sendable { case permissionDenied, staleBookmark, missingFolder, missingFile, unsupportedMedia, corruptedMedia, passwordProtectedPDF, modelUnavailable, providerTimeout, transportBlocked, cancelled, storageFull, databaseError, unknownRedacted }
public enum Retryability: String, Codable, CaseIterable, Sendable { case retry, reauthorize, ignore, rebuildIndex, notRetryable }
public enum ProviderMode: String, Codable, CaseIterable, Sendable { case localFramework, localLoopback, remoteOptIn }
public enum CredentialState: String, Codable, CaseIterable, Sendable { case noneNeeded, keyInKeychain, missingRequired }
public enum ProviderHealthStatus: String, Codable, CaseIterable, Sendable { case unknown, healthy, unavailable, blocked, unauthorized }
