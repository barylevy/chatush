import Foundation

/// OpenAI model provider implementation
@available(iOS 17.0, macOS 14.0, *)
public final class OpenAIModelProvider: ModelProviderProtocol, Sendable {
    public var supportsStreaming: Bool { true }

    private let networkClient: NetworkClientProtocol

    public init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
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

        let openAIMessages = messages.map { message in
            ["role": message.role.rawValue, "content": message.content]
        }

        var requestBody: [String: Any] = [
            "model": config.model,
            "messages": openAIMessages,
        ]

        if let temperature = config.temperature {
            requestBody["temperature"] = temperature
        }

        if let maxTokens = config.maxTokens {
            requestBody["max_tokens"] = maxTokens
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Send request through network layer
        let (data, httpResponse) = try await networkClient.request(request)

        // Handle errors
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ModelProviderError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ModelProviderError.invalidResponse
        }

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

                    let openAIMessages = messages.map { message in
                        ["role": message.role.rawValue, "content": message.content]
                    }

                    var requestBody: [String: Any] = [
                        "model": config.model,
                        "messages": openAIMessages,
                        "stream": true,
                    ]

                    if let temperature = config.temperature {
                        requestBody["temperature"] = temperature
                    }

                    if let maxTokens = config.maxTokens {
                        requestBody["max_tokens"] = maxTokens
                    }

                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

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
                                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                  let choices = json["choices"] as? [[String: Any]],
                                  let firstChoice = choices.first,
                                  let delta = firstChoice["delta"] as? [String: Any],
                                  let content = delta["content"] as? String else {
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
