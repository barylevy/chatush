import Foundation

/// Normalized response from any model provider
public struct ModelResponse: Codable, Sendable {
    public let text: String
    public let provider: String
    public let model: String
    public let latencyMs: Int

    public init(text: String, provider: String, model: String, latencyMs: Int) {
        self.text = text
        self.provider = provider
        self.model = model
        self.latencyMs = latencyMs
    }
}
