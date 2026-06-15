import Foundation
import XCTest
@testable import LocalLens

final class ProviderModelSelectionTests: XCTestCase {
    func testSelectedModelStateDetectsStaleSelections() async {
        let provider = ProviderSetting(id: "ollama", displayName: "Ollama", baseURL: URL(string: "http://localhost:11434/v1")!, isEnabled: true, automaticIndexingEnabled: true, locality: .localLoopback, transportState: .allowedLoopbackHTTP, credentialState: .noneNeeded, modelIDs: ["new"], selectedModelID: "old", lastHealthCheckAt: nil, lastHealthStatus: .unknown)
        let service = ProviderSelectionService(clientFactory: { _ in OpenAICompatibleClient(baseURL: URL(string: "http://127.0.0.1:9/v1")!, providerID: "mock") })
        let state = ProviderModelSelectionState(providerID: provider.id, selectedModelID: provider.selectedModelID, availableModelIDs: provider.modelIDs, availabilityState: provider.hasUsableSelectedModel ? .available : .stale)
        XCTAssertEqual(state.availabilityState, .stale)
        _ = service
    }
}
