import Foundation

/// OpenAI model provider implementation
@available(iOS 17.0, macOS 14.0, *)
public final class OpenAIModelProvider: ModelProviderProtocol, Sendable {
    public var supportsStreaming: Bool { true }

    private let networkClient: NetworkClientProtocol

    public init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - Request/Response Models
    
    private struct OpenAIRequest: Codable {
        let model: String
        let messages: [OpenAIMessage]
        let temperature: Double?
        let maxTokens: Int?
        let stream: Bool?
        
        enum CodingKeys: String, CodingKey {
            case model, messages, temperature, stream
            case maxTokens = "max_tokens"
        }
    }
    
    private struct OpenAIMessage: Codable {
        let role: String
        let content: String
    }
    
    private struct OpenAIResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
            
            struct Message: Codable {
                let content: String
            }
        }
    }
    
    private struct OpenAIStreamResponse: Codable {
        let choices: [StreamChoice]
        
        struct StreamChoice: Codable {
            let delta: Delta
            
            struct Delta: Codable {
                let content: String?
            }
        }
    }

    public func sendPrompt(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse {
        let startTime = Date()

        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw ModelProviderError.missingApiKey
        }

        let endpoint = config.endpoint ?? "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw ModelProviderError.invalidEndpoint
        }

        // Build OpenAI request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let openAIMessages = messages.map { OpenAIMessage(role: $0.role.rawValue, content: $0.content) }
        
        let requestBody = OpenAIRequest(
            model: config.model,
            messages: openAIMessages,
            temperature: config.temperature,
            maxTokens: config.maxTokens,
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
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = response.choices.first?.message.content ?? ""

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        return ModelResponse(
            text: content,
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

                    let endpoint = config.endpoint ?? "https://api.openai.com/v1/chat/completions"
                    guard let url = URL(string: endpoint) else {
                        throw ModelProviderError.invalidEndpoint
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let openAIMessages = messages.map { OpenAIMessage(role: $0.role.rawValue, content: $0.content) }
                    
                    let requestBody = OpenAIRequest(
                        model: config.model,
                        messages: openAIMessages,
                        temperature: config.temperature,
                        maxTokens: config.maxTokens,
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
                                  let streamResponse = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: jsonData),
                                  let content = streamResponse.choices.first?.delta.content else {
                                continue
                            }

                            continuation.yield(content)
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
