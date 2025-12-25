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
            "Failed to save configuration"
        case .loadFailed:
            "Failed to load configuration"
        case .deleteFailed:
            "Failed to delete configuration"
        case .keychainError(let status):
            "Keychain error: \(status)"
        }
    }
}
