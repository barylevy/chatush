import Foundation

final class Conversation: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var providerName: String
    var modelName: String
    var messages: [Message] = []

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        providerName: String,
        modelName: String,
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.providerName = providerName
        self.modelName = modelName
        self.messages = messages
    }

    var lastMessageDate: Date {
        messages.last?.timestamp ?? updatedAt
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}
