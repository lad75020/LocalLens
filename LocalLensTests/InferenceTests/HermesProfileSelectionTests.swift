import Foundation
import XCTest
@testable import LocalLens

final class HermesProfileSelectionTests: XCTestCase {
    func testSelectedHermesProfileReadinessAndStaleState() {
        let ready = HermesProfileSelectionState(selectedProfileID: "office", selectedProfileDisplayName: "Office", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .available)
        XCTAssertTrue(ready.isReadyForOfficeIndexing)
        let stale = HermesProfileSelectionState(selectedProfileID: "missing", selectedProfileDisplayName: "Missing", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .stale)
        XCTAssertFalse(stale.isReadyForOfficeIndexing)
    }

    func testProviderRegistryMergesMissingHermesAgentDefaultWithoutOverwritingPersistedProviders() {
        let registry = ProviderRegistry()
        var persistedOllama = registry.defaultProviders().first { $0.id == "ollama" }!
        persistedOllama.isEnabled = false
        persistedOllama.selectedModelID = "kept-model"
        persistedOllama.modelIDs = ["kept-model"]

        let merged = registry.mergedDefaultProviders(with: [persistedOllama])

        XCTAssertEqual(merged.first?.id, "ollama")
        XCTAssertEqual(merged.first(where: { $0.id == "ollama" })?.isEnabled, false)
        XCTAssertEqual(merged.first(where: { $0.id == "ollama" })?.selectedModelID, "kept-model")
        XCTAssertNotNil(merged.first(where: { $0.id == "hermes-agent" }))
        XCTAssertEqual(registry.missingDefaultProviders(from: [persistedOllama]).map(\.id), ["omlx", "hermes-agent", "custom"])
    }

    func testHermesProfileRefreshReportsMissingCredentialBeforeNetworkRequest() async {
        var provider = ProviderRegistry().defaultProviders().first { $0.id == "hermes-agent" }!
        provider.credentialState = .missingRequired
        let previous = HermesProfileSelectionState(selectedProfileID: "default", selectedProfileDisplayName: "Default")
        let service = ProviderSelectionService(clientFactory: { _ in
            OpenAICompatibleClient(baseURL: URL(string: "http://127.0.0.1:9/v1")!, providerID: "unexpected")
        })

        let state = await service.refreshHermesProfiles(provider: provider, previous: previous)

        XCTAssertEqual(state.availabilityState, .unauthorized)
        XCTAssertEqual(state.selectedProfileID, "default")
        XCTAssertEqual(state.lastSafeError, "Hermes Agent API key is missing.")
        XCTAssertTrue(state.availableProfiles.isEmpty)
    }
}
