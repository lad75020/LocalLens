import Foundation

public enum ProviderRoutingStage: Sendable, Equatable {
    case imageDescription
    case pdfSummary
    case officeSummary
    case embeddings
    case audio
    case video
}

public struct ProviderRouteDecision: Sendable, Equatable {
    public var provider: ProviderSetting?
    public var modelID: String?
    public var hermesProfileID: String?
    public var stage: ProviderRoutingStage
    public var isRequestAllowed: Bool
    public var failureCategory: FailureCategory?
    public var safeMessage: String?

    public static func allowed(stage: ProviderRoutingStage, provider: ProviderSetting, modelID: String?, hermesProfileID: String? = nil) -> ProviderRouteDecision {
        ProviderRouteDecision(provider: provider, modelID: modelID, hermesProfileID: hermesProfileID, stage: stage, isRequestAllowed: true, failureCategory: nil, safeMessage: nil)
    }

    public static func blocked(stage: ProviderRoutingStage, category: FailureCategory, message: String) -> ProviderRouteDecision {
        ProviderRouteDecision(provider: nil, modelID: nil, hermesProfileID: nil, stage: stage, isRequestAllowed: false, failureCategory: category, safeMessage: message)
    }
}

public struct ProviderRoutingService: Sendable {
    public let readinessService: ProviderReadinessService

    public init(readinessService: ProviderReadinessService = ProviderReadinessService()) {
        self.readinessService = readinessService
    }

    public func route(
        stage: ProviderRoutingStage,
        preferredProviderID: String?,
        providers: [ProviderSetting],
        modelStates: [String: ProviderModelSelectionState] = [:],
        hermesProfileState: HermesProfileSelectionState = HermesProfileSelectionState()
    ) -> ProviderRouteDecision {
        switch stage {
        case .audio, .video:
            return .blocked(stage: stage, category: .providerSkipped, message: "AI provider requests are skipped for audio and video.")
        case .embeddings:
            guard let ollama = providers.first(where: { $0.id == BuildConfiguration.fixedEmbeddingProviderID }) else {
                return .blocked(stage: stage, category: .modelUnavailable, message: "Ollama embedding provider is unavailable.")
            }
            let availability = readinessService.fixedOllamaEmbeddingReadiness(ollamaProvider: ollama, modelState: modelStates[ollama.id])
            guard availability == .available else {
                return .blocked(stage: stage, category: availability == .transportBlocked ? .transportBlocked : .modelUnavailable, message: "Embedding model missing: \(BuildConfiguration.fixedEmbeddingModelID)")
            }
            return .allowed(stage: stage, provider: ollama, modelID: BuildConfiguration.fixedEmbeddingModelID)
        case .officeSummary:
            guard let hermes = providers.first(where: { $0.id == "hermes-agent" }) else {
                return .blocked(stage: stage, category: .modelUnavailable, message: "Hermes Agent provider is unavailable.")
            }
            let availability = readinessService.hermesProfileReadiness(for: hermes, hermesProfileState: hermesProfileState)
            guard availability == .available, let profileID = hermesProfileState.selectedProfileID else {
                return .blocked(stage: stage, category: availability == .transportBlocked ? .transportBlocked : .modelUnavailable, message: "Select a valid Hermes profile before Office summaries.")
            }
            return .allowed(stage: stage, provider: hermes, modelID: hermes.effectiveModelID, hermesProfileID: profileID)
        case .imageDescription, .pdfSummary:
            guard let preferredProviderID, let provider = providers.first(where: { $0.id == preferredProviderID }) else {
                return .blocked(stage: stage, category: .modelUnavailable, message: "Select a preferred AI provider before image/PDF enrichment.")
            }
            let availability = readinessService.readinessForPreferredDescription(provider: provider, modelState: modelStates[provider.id], hermesProfileState: hermesProfileState)
            guard availability == .available else {
                return .blocked(stage: stage, category: availability == .transportBlocked ? .transportBlocked : .modelUnavailable, message: "Preferred provider is not ready: \(provider.displayName)")
            }
            let modelID: String?
            if provider.id == "hermes-agent" { modelID = provider.effectiveModelID }
            else { modelID = modelStates[provider.id]?.selectedModelID ?? provider.selectedModelID ?? provider.effectiveModelID }
            return .allowed(stage: stage, provider: provider, modelID: modelID, hermesProfileID: provider.id == "hermes-agent" ? hermesProfileState.selectedProfileID : nil)
        }
    }
}
