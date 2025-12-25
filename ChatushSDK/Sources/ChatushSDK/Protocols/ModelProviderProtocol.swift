import Foundation

/// Protocol defining the interface for all model providers
@available(iOS 18.0, macOS 15.0, *)
public protocol ModelProviderProtocol: Sendable {
    /// Send a prompt to the model and get a response
    /// - Parameters:
    ///   - messages: Array of chat messages for conversation context
    ///   - config: Configuration including model parameters
    /// - Returns: Model response with normalized format
    func sendPrompt(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse

    /// Send a prompt with streaming support
    /// - Parameters:
    ///   - messages: Array of chat messages for conversation context
    ///   - config: Configuration including model parameters
    /// - Returns: AsyncThrowingStream of partial responses
    func sendPromptStreaming(messages: [ChatMessage], config: ModelConfiguration) async -> AsyncThrowingStream<String, Error>

    /// Check if this provider supports streaming
    var supportsStreaming: Bool { get }
}
