import Foundation

@Observable
final class Message: Codable, Identifiable, Equatable {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    var latencyMs: Int?

    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        isFromUser: Bool,
        latencyMs: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.latencyMs = latencyMs
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
