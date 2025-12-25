import Foundation

/// Model for LLM provider configuration
struct LLMProviderConfig: Codable, Sendable {
    var provider: String
    var model: String
    var apiKey: String?
    var endpoint: String?
    var temperature: Double
    var maxTokens: Int
    
    static let defaultConfig = LLMProviderConfig(
        provider: "mock",
        model: "mock-v1",
        apiKey: nil,
        endpoint: nil,
        temperature: 0.7,
        maxTokens: 2000
    )
}
