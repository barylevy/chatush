import Foundation

/// Chat message for conversation context
public struct ChatMessage: Codable, Sendable {
    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }
    
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
