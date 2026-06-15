import Foundation

public struct ProviderSelectionService: Sendable {
    public let credentialStore: ProviderCredentialStore
    public let transportPolicy: ProviderTransportPolicy
    public let redactionPolicy: RedactionPolicy
    public let clientFactory: @Sendable (ProviderSetting) -> OpenAICompatibleClient

    public init(
        credentialStore: ProviderCredentialStore = ProviderCredentialStore(),
        transportPolicy: ProviderTransportPolicy = ProviderTransportPolicy(),
        redactionPolicy: RedactionPolicy = RedactionPolicy(),
        clientFactory: @escaping @Sendable (ProviderSetting) -> OpenAICompatibleClient = { provider in
            OpenAICompatibleClient(baseURL: provider.baseURL, providerID: provider.id)
        }
    ) {
        self.credentialStore = credentialStore
        self.transportPolicy = transportPolicy
        self.redactionPolicy = redactionPolicy
        self.clientFactory = clientFactory
    }

    public func refreshModelSelection(for provider: ProviderSetting, previous: ProviderModelSelectionState? = nil) async -> ProviderModelSelectionState {
        guard provider.transportState == .allowedLoopbackHTTP else {
            return ProviderModelSelectionState(providerID: provider.id, selectedModelID: previous?.selectedModelID ?? provider.selectedModelID, availableModelIDs: provider.modelIDs, availabilityState: .transportBlocked, lastRefreshedAt: Date(), lastSafeError: "Transport is blocked for this provider.")
        }
        do {
            let models = try await clientFactory(provider).models().sorted()
            let selected = previous?.selectedModelID ?? provider.selectedModelID
            let availability: ProviderSelectionAvailability
            if models.isEmpty { availability = .unavailable }
            else if let selected, !models.contains(selected) { availability = .stale }
            else if selected == nil { availability = .unknown }
            else { availability = .available }
            return ProviderModelSelectionState(providerID: provider.id, selectedModelID: selected, availableModelIDs: models, availabilityState: availability, lastRefreshedAt: Date(), lastSafeError: nil)
        } catch {
            return ProviderModelSelectionState(providerID: provider.id, selectedModelID: previous?.selectedModelID ?? provider.selectedModelID, availableModelIDs: previous?.availableModelIDs ?? provider.modelIDs, availabilityState: .unavailable, lastRefreshedAt: Date(), lastSafeError: redactionPolicy.safeMessage(error.localizedDescription))
        }
    }

    public func refreshHermesProfiles(provider: ProviderSetting, previous: HermesProfileSelectionState? = nil) async -> HermesProfileSelectionState {
        guard provider.id == "hermes-agent", provider.isEnabled else {
            return HermesProfileSelectionState(selectedProfileID: previous?.selectedProfileID, selectedProfileDisplayName: previous?.selectedProfileDisplayName, availableProfiles: previous?.availableProfiles ?? [], availabilityState: .unavailable, lastRefreshedAt: Date(), lastSafeError: "Hermes Agent provider is disabled.")
        }
        guard provider.transportState == .allowedLoopbackHTTP else {
            return HermesProfileSelectionState(selectedProfileID: previous?.selectedProfileID, selectedProfileDisplayName: previous?.selectedProfileDisplayName, availableProfiles: previous?.availableProfiles ?? [], availabilityState: .transportBlocked, lastRefreshedAt: Date(), lastSafeError: "Transport is blocked for Hermes Agent.")
        }
        do {
            let profiles = try await clientFactory(provider).hermesProfiles()
            let previousID = previous?.selectedProfileID
            let autoDefault = profiles.count == 1 ? profiles.first?.id : profiles.first(where: { $0.isDefault })?.id
            let selectedID = previousID ?? autoDefault
            let selectedProfile = selectedID.flatMap { id in profiles.first { $0.id == id } }
            let availability: ProviderSelectionAvailability
            if profiles.isEmpty { availability = .unavailable }
            else if selectedID == nil { availability = .unknown }
            else if selectedProfile == nil { availability = .stale }
            else { availability = .available }
            return HermesProfileSelectionState(selectedProfileID: selectedID, selectedProfileDisplayName: selectedProfile?.displayName ?? previous?.selectedProfileDisplayName, availableProfiles: profiles, availabilityState: availability, lastRefreshedAt: Date(), lastSafeError: nil)
        } catch {
            return HermesProfileSelectionState(selectedProfileID: previous?.selectedProfileID, selectedProfileDisplayName: previous?.selectedProfileDisplayName, availableProfiles: previous?.availableProfiles ?? [], availabilityState: .unavailable, lastRefreshedAt: Date(), lastSafeError: redactionPolicy.safeMessage(error.localizedDescription))
        }
    }

    public static func apply(_ state: ProviderModelSelectionState, to provider: ProviderSetting) -> ProviderSetting {
        var updated = provider
        updated.modelIDs = state.availableModelIDs
        updated.selectedModelID = state.selectedModelID
        updated.lastHealthCheckAt = state.lastRefreshedAt
        updated.lastHealthStatus = state.availabilityState == .available ? .healthy : (state.availabilityState == .transportBlocked ? .blocked : .unavailable)
        return updated
    }
}
