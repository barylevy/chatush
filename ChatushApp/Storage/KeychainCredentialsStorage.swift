import Foundation
import Security

/// Keychain-based credentials storage implementation
final class KeychainCredentialsStorage: CredentialsStorageProtocol, @unchecked Sendable {
    nonisolated init() {}
    
    private let service = "com.chatush.credentials"
    private let account = "llm-configurations-data"

    nonisolated func saveConfigurations(_ data: LLMConfigurationsData) async throws {
        let encoder = JSONEncoder()
        let jsonData = try await Task.detached {
            try encoder.encode(data)
        }.value

        // Delete existing item first
        try? await deleteConfigurations()

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: jsonData,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw CredentialsStorageError.keychainError(status)
        }
    }

    nonisolated func loadConfigurations() async throws -> LLMConfigurationsData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let jsonData = result as? Data else {
            if status == errSecItemNotFound {
                return nil
            }
            throw CredentialsStorageError.keychainError(status)
        }

        let decoder = JSONDecoder()
        return try await Task.detached {
            try decoder.decode(LLMConfigurationsData.self, from: jsonData)
        }.value
    }

    nonisolated func deleteConfigurations() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialsStorageError.keychainError(status)
        }
    }

    nonisolated func getStorageType() -> String {
        "Keychain"
    }
}
