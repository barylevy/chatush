import Foundation

/// Anthropic Claude model provider implementation
@available(iOS 17.0, macOS 14.0, *)
public final class ClaudeModelProvider: ModelProviderProtocol, Sendable {
    public var supportsStreaming: Bool { true }

    private let networkClient: NetworkClientProtocol

    public init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - Request/Response Models
    
    private struct ClaudeRequest: Codable {
        let model: String
        let messages: [ClaudeMessage]
        let maxTokens: Int
        let temperature: Double?
        let stream: Bool?
        
        enum CodingKeys: String, CodingKey {
            case model, messages, temperature, stream
            case maxTokens = "max_tokens"
        }
    }
    
    private struct ClaudeMessage: Codable {
        let role: String
        let content: String
    }
    
    private struct ClaudeResponse: Codable {
        let content: [ContentBlock]
        
        struct ContentBlock: Codable {
            let text: String
        }
    }
    
    private struct ClaudeStreamEvent: Codable {
        let type: String
        let delta: Delta?
        
        struct Delta: Codable {
            let text: String?
        }
    }

    public func sendPrompt(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse {
        let startTime = Date()

        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw ModelProviderError.missingApiKey
        }

        let endpoint = config.endpoint ?? "https://api.anthropic.com/v1/messages"
        guard let url = URL(string: endpoint) else {
            throw ModelProviderError.invalidEndpoint
        }

        // Build Claude request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        // Convert messages to Claude format
        let claudeMessages = messages.map { message in
            ClaudeMessage(
                role: message.role.rawValue == "system" ? "user" : message.role.rawValue,
                content: message.content
            )
        }
        
        let requestBody = ClaudeRequest(
            model: config.model,
            messages: claudeMessages,
            maxTokens: config.maxTokens ?? 2000,
            temperature: config.temperature,
            stream: nil
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        // Send request through network layer
        let (data, httpResponse) = try await networkClient.request(request)

        // Handle errors
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ModelProviderError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Parse response
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let text = response.content.first?.text ?? ""

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        return ModelResponse(
            text: text,
            provider: config.provider,
            model: config.model,
            latencyMs: latencyMs
        )
    }

    public func sendPromptStreaming(messages: [ChatMessage], config: ModelConfiguration) async -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = config.apiKey, !apiKey.isEmpty else {
                        throw ModelProviderError.missingApiKey
                    }

                    let endpoint = config.endpoint ?? "https://api.anthropic.com/v1/messages"
                    guard let url = URL(string: endpoint) else {
                        throw ModelProviderError.invalidEndpoint
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                    let claudeMessages = messages.map { message in
                        ClaudeMessage(
                            role: message.role.rawValue == "system" ? "user" : message.role.rawValue,
                            content: message.content
                        )
                    }
                    
                    let requestBody = ClaudeRequest(
                        model: config.model,
                        messages: claudeMessages,
                        maxTokens: config.maxTokens ?? 2000,
                        temperature: config.temperature,
                        stream: true
                    )

                    request.httpBody = try JSONEncoder().encode(requestBody)

                    // Use network layer for streaming
                    let stream = try await networkClient.streamRequest(request)

                    for try await data in stream {
                        guard let line = String(data: data, encoding: .utf8) else {
                            continue
                        }

                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))

                            if jsonString == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            guard let jsonData = jsonString.data(using: .utf8),
                                  let event = try? JSONDecoder().decode(ClaudeStreamEvent.self, from: jsonData) else {
                                continue
                            }

                            // Claude streaming format
                            if event.type == "content_block_delta" {
                                if let text = event.delta?.text {
                                    continuation.yield(text)
                                }
                            } else if event.type == "message_stop" {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
