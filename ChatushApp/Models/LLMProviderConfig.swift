import Foundation

/// Model for LLM provider configuration
struct LLMProviderConfig: Codable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var provider: String
    var model: String
    var apiKey: String?
    var endpoint: String?
    var temperature: Double
    var maxTokens: Int

    static let mockConfig = LLMProviderConfig(
        id: UUID(),
        name: "Mock (Local)",
        provider: "mock",
        model: "mock-v1",
        apiKey: nil,
        endpoint: nil,
        temperature: 0.7,
        maxTokens: 2000
    )
    
    static let openAIConfig = LLMProviderConfig(
        id: UUID(),
        name: "OpenAI",
        provider: "openai",
        model: "gpt-4o-mini",
        apiKey: nil,
        endpoint: nil,
        temperature: 0.7,
        maxTokens: 2000
    )
    
    static let defaultConfigs = [mockConfig, openAIConfig]
}
