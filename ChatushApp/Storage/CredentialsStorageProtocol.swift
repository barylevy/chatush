import Foundation

/// Protocol for storing and retrieving LLM configurations
protocol CredentialsStorageProtocol: Sendable {
    nonisolated func saveConfigurations(_ data: LLMConfigurationsData) async throws
    nonisolated func loadConfigurations() async throws -> LLMConfigurationsData?
    nonisolated func deleteConfigurations() async throws
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
