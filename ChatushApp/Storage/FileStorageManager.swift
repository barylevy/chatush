import Foundation

/// Protocol for file-based storage management
protocol FileStorageManagerProtocol: Sendable {
    func loadConversations() async throws -> [Conversation]
    func saveConversations(_ conversations: [Conversation]) async throws
    func clearAllData() async throws
}

/// Manages JSON file storage for conversations
actor FileStorageManager: FileStorageManagerProtocol {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(fileName: String = "conversations.json") {
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Configure encoder/decoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func loadConversations() async throws -> [Conversation] {
        // If file doesn't exist, return empty array
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let conversations = try decoder.decode([Conversation].self, from: data)
        return conversations
    }
    
    func saveConversations(_ conversations: [Conversation]) async throws {
        let data = try encoder.encode(conversations)
        try data.write(to: fileURL, options: [.atomic])
    }
    
    func clearAllData() async throws {
        // Delete the file if it exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
