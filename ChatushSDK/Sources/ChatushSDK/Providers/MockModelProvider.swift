import Foundation

/// Mock model provider for testing and local development
@available(iOS 18.0, macOS 15.0, *)
public final class MockModelProvider: ModelProviderProtocol, Sendable {
    
    public var supportsStreaming: Bool { true }
    
    private let predefinedResponses: [String] = [
        "That's an interesting question! Let me think about that...",
        "I understand what you're asking. Here's my perspective:",
        "Great point! I'd like to add to that:",
        "I'm here to help! Let me explain:",
        "That's a thoughtful question. Consider this:",
        "Absolutely! Here's what I think:",
        "I appreciate you asking. My response is:",
        "Let me break that down for you:",
        "That's worth exploring further. Here's why:",
        "I'm processing that. Here's my take:"
    ]
    
    public init() {}
    
    public func sendPrompt(messages: [ChatMessage], config: ModelConfiguration) async throws -> ModelResponse {
        let startTime = Date()
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        
        guard let lastMessage = messages.last else {
            throw ModelProviderError.invalidRequest
        }
        
        // Generate response: echo + random predefined response
        let randomResponse = predefinedResponses.randomElement() ?? "I'm here to help!"
        let responseText = """
        Echo: "\(lastMessage.content)"
        
        \(randomResponse)
        """
        
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return ModelResponse(
            text: responseText,
            provider: config.provider,
            model: config.model,
            latencyMs: latencyMs
        )
    }
    
    public func sendPromptStreaming(messages: [ChatMessage], config: ModelConfiguration) async -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let lastMessage = messages.last else {
                        throw ModelProviderError.invalidRequest
                    }
                    
                    let randomResponse = predefinedResponses.randomElement() ?? "I'm here to help!"
                    let fullResponse = """
                    Echo: "\(lastMessage.content)"
                    
                    \(randomResponse)
                    """
                    
                    // Stream word by word
                    let words = fullResponse.split(separator: " ")
                    for (index, word) in words.enumerated() {
                        try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay per word
                        if index == words.count - 1 {
                            continuation.yield(String(word))
                        } else {
                            continuation.yield(String(word) + " ")
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
