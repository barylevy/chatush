import Foundation

/// Router that determines which provider to use based on configuration
@available(iOS 17.0, macOS 14.0, *)
public actor ModelRouter {
    private var providers: [String: ModelProviderProtocol] = [:]
    private let networkClient: NetworkClientProtocol

    public init(networkClient: NetworkClientProtocol? = nil) {
        self.networkClient = networkClient ?? NetworkClient()
        // Register default providers with network client
        providers["openai"] = OpenAIModelProvider(networkClient: self.networkClient)
        providers["claude"] = ClaudeModelProvider(networkClient: self.networkClient)
        providers["mock"] = MockModelProvider()
    }

    /// Register a custom provider
    public func registerProvider(name: String, provider: ModelProviderProtocol) {
        providers[name.lowercased()] = provider
    }

    /// Send a prompt using the configured provider
    public func sendPrompt(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse {
        let providerName = config.provider.lowercased()
        guard let provider = providers[providerName] else {
            throw ModelProviderError.unsupportedProvider(config.provider)
        }

        return try await provider.sendPrompt(messages: messages, config: config)
    }

    /// Send a prompt with streaming using the configured provider
    public func sendPromptStreaming(messages: [ChatMessage], config: ModelConfiguration) async -> AsyncThrowingStream<String, Error> {
        let providerName = config.provider.lowercased()
        guard let provider = providers[providerName] else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: ModelProviderError.unsupportedProvider(config.provider))
            }
        }

        if !provider.supportsStreaming {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let response = try await provider.sendPrompt(messages: messages, config: config)
                        continuation.yield(response.text)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }

        return await provider.sendPromptStreaming(messages: messages, config: config)
    }

    /// Check if a provider supports streaming
    public func supportsStreaming(provider: String) -> Bool {
        providers[provider.lowercased()]?.supportsStreaming ?? false
    }
}
