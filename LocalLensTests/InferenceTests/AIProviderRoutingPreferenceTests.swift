import XCTest
@testable import LocalLens

final class AIProviderRoutingPreferenceTests: XCTestCase {
    func testPreferredProviderRoutesImageAndPDFWithoutFallback() {
        let providers = [
            provider(id: "ollama", models: ["llama3", BuildConfiguration.fixedEmbeddingModelID], selected: "llama3"),
            provider(id: "omlx", models: ["mlx-generation"], selected: "mlx-generation")
        ]
        let modelStates = [
            "ollama": ProviderModelSelectionState(providerID: "ollama", selectedModelID: "llama3", availableModelIDs: ["llama3", BuildConfiguration.fixedEmbeddingModelID], availabilityState: .available),
            "omlx": ProviderModelSelectionState(providerID: "omlx", selectedModelID: "mlx-generation", availableModelIDs: ["mlx-generation"], availabilityState: .available)
        ]
        let service = ProviderRoutingService()

        let imageRoute = service.route(stage: .imageDescription, preferredProviderID: "omlx", providers: providers, modelStates: modelStates)
        let pdfRoute = service.route(stage: .pdfSummary, preferredProviderID: "omlx", providers: providers, modelStates: modelStates)
        let missingRoute = service.route(stage: .imageDescription, preferredProviderID: "custom", providers: providers, modelStates: modelStates)

        XCTAssertTrue(imageRoute.isRequestAllowed)
        XCTAssertEqual(imageRoute.provider?.id, "omlx")
        XCTAssertEqual(imageRoute.modelID, "mlx-generation")
        XCTAssertTrue(pdfRoute.isRequestAllowed)
        XCTAssertEqual(pdfRoute.provider?.id, "omlx")
        XCTAssertFalse(missingRoute.isRequestAllowed)
        XCTAssertNil(missingRoute.provider)
    }

    func testOfficeAlwaysRoutesToHermesRegardlessOfPreferredProvider() {
        let hermes = provider(id: "hermes-agent", models: ["hermes-default"], selected: "hermes-default")
        let profile = HermesProfileSelectionState(
            selectedProfileID: "work",
            selectedProfileDisplayName: "Work",
            availableProfiles: [HermesProfileSummary(id: "work", displayName: "Work")],
            availabilityState: .available
        )

        let route = ProviderRoutingService().route(stage: .officeSummary, preferredProviderID: "ollama", providers: [hermes], hermesProfileState: profile)

        XCTAssertTrue(route.isRequestAllowed)
        XCTAssertEqual(route.provider?.id, "hermes-agent")
        XCTAssertEqual(route.hermesProfileID, "work")
    }

    func testReadinessRequiresHermesProfileAndGenerationModels() {
        let service = ProviderReadinessService()
        let ollama = provider(id: "ollama", models: [BuildConfiguration.fixedEmbeddingModelID], selected: nil)
        let omlx = provider(id: "omlx", models: ["mlx-generation"], selected: nil)
        let hermes = provider(id: "hermes-agent", models: ["hermes"], selected: "hermes")

        XCTAssertNotEqual(service.readinessForPreferredDescription(provider: ollama, modelState: nil, hermesProfileState: HermesProfileSelectionState()), .available)
        XCTAssertNotEqual(service.readinessForPreferredDescription(provider: omlx, modelState: nil, hermesProfileState: HermesProfileSelectionState()), .available)
        XCTAssertNotEqual(service.readinessForPreferredDescription(provider: hermes, modelState: nil, hermesProfileState: HermesProfileSelectionState()), .available)
    }

    func testEmbeddingRouteIsAlwaysOllamaQwen3Embedding4b() {
        let providers = [
            provider(id: "omlx", models: ["embedding-looking-model"], selected: "embedding-looking-model"),
            provider(id: "ollama", models: ["chat", BuildConfiguration.fixedEmbeddingModelID], selected: "chat")
        ]

        let route = ProviderRoutingService().route(stage: .embeddings, preferredProviderID: "omlx", providers: providers)

        XCTAssertTrue(route.isRequestAllowed)
        XCTAssertEqual(route.provider?.id, BuildConfiguration.fixedEmbeddingProviderID)
        XCTAssertEqual(route.modelID, BuildConfiguration.fixedEmbeddingModelID)
    }

    func testAudioAndVideoRoutesNeverAllowProviderRequests() {
        let providers = [provider(id: "ollama", models: [BuildConfiguration.fixedEmbeddingModelID], selected: BuildConfiguration.fixedEmbeddingModelID)]
        let service = ProviderRoutingService()

        let audio = service.route(stage: .audio, preferredProviderID: "ollama", providers: providers)
        let video = service.route(stage: .video, preferredProviderID: "ollama", providers: providers)

        XCTAssertFalse(audio.isRequestAllowed)
        XCTAssertFalse(video.isRequestAllowed)
        XCTAssertEqual(audio.failureCategory, .providerSkipped)
        XCTAssertEqual(video.failureCategory, .providerSkipped)
    }

    private func provider(id: String, models: [String], selected: String?) -> ProviderSetting {
        ProviderSetting(
            id: id,
            displayName: id,
            baseURL: URL(string: "http://localhost:11434/v1")!,
            isEnabled: true,
            automaticIndexingEnabled: true,
            locality: .localLoopback,
            transportState: .allowedLoopbackHTTP,
            credentialState: .noneNeeded,
            modelIDs: models,
            selectedModelID: selected,
            lastHealthCheckAt: nil,
            lastHealthStatus: .healthy
        )
    }
}
