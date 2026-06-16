import Foundation

public enum ProviderReadinessPurpose: Sendable, Equatable {
    case preferredDescription
    case officeSummary
    case embedding
}

public struct ProviderReadinessService: Sendable {
    public static let fixedEmbeddingProviderID = BuildConfiguration.fixedEmbeddingProviderID
    public static let fixedEmbeddingModelID = BuildConfiguration.fixedEmbeddingModelID

    public init() {}

    public func readiness(
        for provider: ProviderSetting,
        preferredProviderID: String,
        modelState: ProviderModelSelectionState? = nil,
        hermesProfileState: HermesProfileSelectionState = HermesProfileSelectionState()
    ) -> ProviderReadinessState {
        let generation = generationModelReadiness(for: provider, modelState: modelState)
        let hermes = hermesProfileReadiness(for: provider, hermesProfileState: hermesProfileState)
        let embedding = fixedOllamaEmbeddingReadiness(ollamaProvider: provider, modelState: modelState)
        let preferred: ProviderSelectionAvailability = provider.id == preferredProviderID ? readinessForPreferredDescription(provider: provider, modelState: modelState, hermesProfileState: hermesProfileState) : .unknown
        return ProviderReadinessState(
            providerID: provider.id,
            transportState: provider.transportState,
            credentialState: provider.credentialState,
            generationModelState: generation,
            hermesProfileState: hermes,
            preferredProviderState: preferred,
            embeddingModelState: embedding,
            lastSafeError: safeError(for: provider, generation: generation, hermes: hermes, embedding: embedding, preferred: preferred)
        )
    }

    public func readinessForPreferredDescription(provider: ProviderSetting, modelState: ProviderModelSelectionState?, hermesProfileState: HermesProfileSelectionState) -> ProviderSelectionAvailability {
        guard provider.transportState == .allowedLoopbackHTTP else { return .transportBlocked }
        guard provider.credentialState != .missingRequired else { return .unauthorized }
        switch provider.id {
        case "hermes-agent":
            return hermesProfileReadiness(for: provider, hermesProfileState: hermesProfileState)
        case "ollama", "omlx":
            return generationModelReadiness(for: provider, modelState: modelState)
        default:
            return .available
        }
    }

    public func generationModelReadiness(for provider: ProviderSetting, modelState: ProviderModelSelectionState?) -> ProviderSelectionAvailability {
        guard provider.id == "ollama" || provider.id == "omlx" else { return .unknown }
        guard provider.transportState == .allowedLoopbackHTTP else { return .transportBlocked }
        let selected = modelState?.selectedModelID ?? provider.selectedModelID
        let available = modelState?.availableModelIDs.isEmpty == false ? (modelState?.availableModelIDs ?? []) : provider.modelIDs
        guard let selected, !selected.isEmpty else { return .unavailable }
        guard available.contains(selected) else { return .stale }
        return .available
    }

    public func hermesProfileReadiness(for provider: ProviderSetting, hermesProfileState: HermesProfileSelectionState) -> ProviderSelectionAvailability {
        guard provider.id == "hermes-agent" else { return .unknown }
        guard provider.transportState == .allowedLoopbackHTTP else { return .transportBlocked }
        guard provider.credentialState != .missingRequired else { return .unauthorized }
        guard let selected = hermesProfileState.selectedProfileID, !selected.isEmpty else { return .unavailable }
        guard hermesProfileState.availableProfiles.contains(where: { $0.id == selected }) else { return .stale }
        return hermesProfileState.availabilityState == .available ? .available : hermesProfileState.availabilityState
    }

    public func fixedOllamaEmbeddingReadiness(ollamaProvider provider: ProviderSetting?, modelState: ProviderModelSelectionState? = nil) -> ProviderSelectionAvailability {
        guard let provider, provider.id == Self.fixedEmbeddingProviderID else { return .unavailable }
        guard provider.transportState == .allowedLoopbackHTTP else { return .transportBlocked }
        let available = modelState?.availableModelIDs.isEmpty == false ? (modelState?.availableModelIDs ?? []) : provider.modelIDs
        return available.contains(Self.fixedEmbeddingModelID) ? .available : .unavailable
    }

    private func safeError(for provider: ProviderSetting, generation: ProviderSelectionAvailability, hermes: ProviderSelectionAvailability, embedding: ProviderSelectionAvailability, preferred: ProviderSelectionAvailability) -> String? {
        if provider.transportState != .allowedLoopbackHTTP { return "Transport blocked" }
        if provider.credentialState == .missingRequired { return "Credential required" }
        if provider.id == "hermes-agent", hermes != .available { return "Select a valid Hermes profile" }
        if (provider.id == "ollama" || provider.id == "omlx"), generation != .available { return "Choose a valid generation model" }
        if provider.id == Self.fixedEmbeddingProviderID, embedding != .available { return "Embedding model missing: \(Self.fixedEmbeddingModelID)" }
        if preferred == .transportBlocked { return "Transport blocked" }
        return nil
    }
}
