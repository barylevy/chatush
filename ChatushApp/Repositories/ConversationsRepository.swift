import Foundation
import SwiftData

@MainActor
final class ConversationsRepository: ConversationsRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchConversations(limit: Int, offset: Int) async throws -> [Conversation] {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        let allConversations = try modelContext.fetch(descriptor)
        
        // Apply manual paging
        let startIndex = min(offset, allConversations.count)
        let endIndex = min(offset + limit, allConversations.count)
        
        guard startIndex < endIndex else {
            return []
        }
        
        return Array(allConversations[startIndex..<endIndex])
    }
    
    func fetchConversation(id: UUID) async throws -> Conversation? {
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func createConversation(title: String, providerName: String, modelName: String) async throws -> Conversation {
        let conversation = Conversation(
            title: title,
            providerName: providerName,
            modelName: modelName
        )
        modelContext.insert(conversation)
        try modelContext.save()
        return conversation
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        conversation.updatedAt = Date()
        try modelContext.save()
    }
    
    func deleteConversation(_ conversation: Conversation) async throws {
        modelContext.delete(conversation)
        try modelContext.save()
    }
    
    func addMessage(to conversation: Conversation, content: String, isFromUser: Bool, latencyMs: Int?) async throws -> Message {
        let message = Message(
            content: content,
            isFromUser: isFromUser,
            latencyMs: latencyMs
        )
        message.conversation = conversation
        conversation.messages.append(message)
        conversation.updatedAt = Date()
        
        modelContext.insert(message)
        try modelContext.save()
        
        return message
    }
    
    func deleteMessage(_ message: Message, from conversation: Conversation) async throws {
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            conversation.messages.remove(at: index)
        }
        modelContext.delete(message)
        try modelContext.save()
    }
    
    func deleteMessages(_ messages: [Message], from conversation: Conversation) async throws {
        for message in messages {
            if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
                conversation.messages.remove(at: index)
            }
            modelContext.delete(message)
        }
        try modelContext.save()
    }
    
    func clearConversation(_ conversation: Conversation) async throws {
        let messagesToDelete = conversation.messages
        for message in messagesToDelete {
            modelContext.delete(message)
        }
        conversation.messages.removeAll()
        try modelContext.save()
    }
    
    func fetchAllConversations() async throws -> [Conversation] {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
