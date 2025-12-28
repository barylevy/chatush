import Foundation

@MainActor
final class ConversationsRepository: ConversationsRepositoryProtocol {
    private let storage: FileStorageManagerProtocol
    private var conversations: [Conversation] = []
    
    init(storage: FileStorageManagerProtocol) {
        self.storage = storage
    }
    
    // Load conversations from storage on first access
    private func loadConversationsIfNeeded() async throws {
        if conversations.isEmpty {
            conversations = try await storage.loadConversations()
        }
    }
    
    // Save all conversations to storage
    private func saveConversations() async throws {
        try await storage.saveConversations(conversations)
    }

    func fetchConversations(limit: Int, offset: Int) async throws -> [Conversation] {
        try await loadConversationsIfNeeded()
        
        // Sort by updatedAt descending
        let sorted = conversations.sorted { $0.updatedAt > $1.updatedAt }
        
        // Apply manual paging
        let startIndex = min(offset, sorted.count)
        let endIndex = min(offset + limit, sorted.count)
        
        guard startIndex < endIndex else {
            return []
        }
        
        return Array(sorted[startIndex ..< endIndex])
    }

    func fetchConversation(id: UUID) async throws -> Conversation? {
        try await loadConversationsIfNeeded()
        return conversations.first { $0.id == id }
    }

    func createConversation(title: String, providerName: String, modelName: String) async throws -> Conversation {
        try await loadConversationsIfNeeded()
        
        let conversation = Conversation(
            title: title,
            providerName: providerName,
            modelName: modelName
        )
        conversations.append(conversation)
        try await saveConversations()
        return conversation
    }

    func updateConversation(_ conversation: Conversation) async throws {
        try await loadConversationsIfNeeded()
        
        conversation.updatedAt = Date()
        try await saveConversations()
    }

    func deleteConversation(_ conversation: Conversation) async throws {
        try await loadConversationsIfNeeded()
        
        conversations.removeAll { $0.id == conversation.id }
        try await saveConversations()
    }

    func addMessage(to conversation: Conversation, content: String, isFromUser: Bool, latencyMs: Int?) async throws -> Message {
        try await loadConversationsIfNeeded()
        
        let message = Message(
            content: content,
            isFromUser: isFromUser,
            latencyMs: latencyMs
        )
        conversation.messages.append(message)
        conversation.updatedAt = Date()
        
        try await saveConversations()
        return message
    }

    func deleteMessage(_ message: Message, from conversation: Conversation) async throws {
        try await loadConversationsIfNeeded()
        
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            conversation.messages.remove(at: index)
        }
        try await saveConversations()
    }

    func deleteMessages(_ messages: [Message], from conversation: Conversation) async throws {
        try await loadConversationsIfNeeded()
        
        for message in messages {
            if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
                conversation.messages.remove(at: index)
            }
        }
        try await saveConversations()
    }

    func clearConversation(_ conversation: Conversation) async throws {
        try await loadConversationsIfNeeded()
        
        conversation.messages.removeAll()
        try await saveConversations()
    }

    func fetchAllConversations() async throws -> [Conversation] {
        try await loadConversationsIfNeeded()
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }
}
