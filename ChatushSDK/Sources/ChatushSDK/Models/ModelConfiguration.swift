import Foundation

/// Configuration for model request
public struct ModelConfiguration: Codable, Sendable {
    public let provider: String
    public let model: String
    public let apiKey: String?
    public let endpoint: String?
    public let temperature: Double?
    public let maxTokens: Int?

    public init(
        provider: String,
        model: String,
        apiKey: String? = nil,
        endpoint: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) {
        self.provider = provider
        self.model = model
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}
