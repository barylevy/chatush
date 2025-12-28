import Foundation

/// Main SDK interface for Chatush
@available(iOS 17.0, macOS 14.0, *)
public actor ChatushSDK {
    private let router: ModelRouter

    public init(networkClient: NetworkClientProtocol? = nil) {
        router = ModelRouter(networkClient: networkClient ?? NetworkClient())
    }

    /// Send a message and get a response
    /// - Parameters:
    ///   - messages: Conversation history
    ///   - config: Model configuration
    /// - Returns: Model response
    public func sendMessage(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse {
        try await router.sendPrompt(messages: messages, config: config)
    }

    /// Send a message with streaming support
    /// - Parameters:
    ///   - messages: Conversation history
    ///   - config: Model configuration
    /// - Returns: AsyncThrowingStream of partial responses
    public func sendMessageStreaming(messages: [ChatMessage], config: ModelConfiguration) async -> AsyncThrowingStream<String, Error> {
        await router.sendPromptStreaming(messages: messages, config: config)
    }

    /// Check if current provider supports streaming
    public func supportsStreaming(provider: String) async -> Bool {
        await router.supportsStreaming(provider: provider)
    }
}
