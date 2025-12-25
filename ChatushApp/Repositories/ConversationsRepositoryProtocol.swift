import Foundation
import SwiftData

/// Protocol for managing conversations repository
protocol ConversationsRepositoryProtocol: Sendable {
    func fetchConversations(limit: Int, offset: Int) async throws -> [Conversation]
    func fetchConversation(id: UUID) async throws -> Conversation?
    func createConversation(title: String, providerName: String, modelName: String) async throws -> Conversation
    func updateConversation(_ conversation: Conversation) async throws
    func deleteConversation(_ conversation: Conversation) async throws
    func addMessage(to conversation: Conversation, content: String, isFromUser: Bool, latencyMs: Int?) async throws -> Message
    func deleteMessage(_ message: Message, from conversation: Conversation) async throws
    func deleteMessages(_ messages: [Message], from conversation: Conversation) async throws
    func clearConversation(_ conversation: Conversation) async throws
    func fetchAllConversations() async throws -> [Conversation]
}
