import Foundation

public enum BuildConfiguration {
    public static let minimumMacOSVersion = "26.0"
    public static let omlxBaseURL = URL(string: "http://localhost:17998/v1")!
    public static let ollamaBaseURL = URL(string: "http://localhost:11434/v1")!
    public static let hermesAgentBaseURL = URL(string: "http://localhost:8642/v1")!
    public static let discoveryConcurrencyLimit = 4
    public static let providerConcurrencyLimit = 2
    public static let thumbnailMaxDimension = 512
    public static let videoMaxSampledFrames = 12
    public static let maxSearchResults = 100
    public static let maxPromptCharacters = 12_000
    public static let maxProviderQueryCharacters = 512
    public static let fixedEmbeddingProviderID = "ollama"
    public static let fixedEmbeddingModelID = "qwen3-embedding:4b"
    public static let preferredAIProviderSettingKey = "preferredAIProviderID"
    public static let providerTimeoutSeconds: TimeInterval = 30
}
