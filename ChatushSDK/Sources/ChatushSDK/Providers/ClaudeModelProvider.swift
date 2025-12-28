import Foundation

/// Anthropic Claude model provider implementation
@available(iOS 17.0, macOS 14.0, *)
public final class ClaudeModelProvider: ModelProviderProtocol, Sendable {
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
            ["role": message.role.rawValue == "system" ? "user" : message.role.rawValue, "content": message.content]
        }

        var requestBody: [String: Any] = [
            "model": config.model,
            "messages": claudeMessages,
            "max_tokens": config.maxTokens ?? 2000,
        ]

        if let temperature = config.temperature {
            requestBody["temperature"] = temperature
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
        guard let content = json?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ModelProviderError.invalidResponse
        }

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
                        ["role": message.role.rawValue == "system" ? "user" : message.role.rawValue, "content": message.content]
                    }

                    var requestBody: [String: Any] = [
                        "model": config.model,
                        "messages": claudeMessages,
                        "max_tokens": config.maxTokens ?? 2000,
                        "stream": true,
                    ]

                    if let temperature = config.temperature {
                        requestBody["temperature"] = temperature
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
                                  let type = json["type"] as? String else {
                                continue
                            }

                            // Claude streaming format
                            if type == "content_block_delta" {
                                if let delta = json["delta"] as? [String: Any],
                                   let text = delta["text"] as? String {
                                    continuation.yield(text)
                                }
                            } else if type == "message_stop" {
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
