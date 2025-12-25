import Foundation

/// Protocol for storing and retrieving credentials
protocol CredentialsStorageProtocol: Sendable {
    nonisolated func saveConfig(_ config: LLMProviderConfig) async throws
    nonisolated func loadConfig() async throws -> LLMProviderConfig?
    nonisolated func deleteConfig() async throws
    nonisolated func getStorageType() -> String
}

enum CredentialsStorageError: LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save configuration"
        case .loadFailed:
            return "Failed to load configuration"
        case .deleteFailed:
            return "Failed to delete configuration"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}
