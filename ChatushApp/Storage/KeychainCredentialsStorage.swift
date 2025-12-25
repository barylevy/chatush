import Foundation
import Security

/// Keychain-based credentials storage implementation
final class KeychainCredentialsStorage: CredentialsStorageProtocol, @unchecked Sendable {
    private let service = "com.chatush.credentials"
    private let account = "llm-provider-config"

    nonisolated func saveConfig(_ config: LLMProviderConfig) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        // Delete existing item first
        try? await deleteConfig()

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw CredentialsStorageError.keychainError(status)
        }
    }

    nonisolated func loadConfig() async throws -> LLMProviderConfig? {
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
              let data = result as? Data else {
            if status == errSecItemNotFound {
                return nil
            }
            throw CredentialsStorageError.keychainError(status)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(LLMProviderConfig.self, from: data)
    }

    nonisolated func deleteConfig() async throws {
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
