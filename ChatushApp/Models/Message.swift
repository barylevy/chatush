import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    var latencyMs: Int?
    
    var conversation: Conversation?
    
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
}
