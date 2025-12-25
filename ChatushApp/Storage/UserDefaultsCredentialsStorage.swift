import Foundation

/// UserDefaults-based credentials storage implementation
final class UserDefaultsCredentialsStorage: CredentialsStorageProtocol, @unchecked Sendable {
    
    private let key = "llm-provider-config"
    private let userDefaults = UserDefaults.standard
    
    nonisolated func saveConfig(_ config: LLMProviderConfig) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        userDefaults.set(data, forKey: key)
    }
    
    nonisolated func loadConfig() async throws -> LLMProviderConfig? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(LLMProviderConfig.self, from: data)
    }
    
    nonisolated func deleteConfig() async throws {
        userDefaults.removeObject(forKey: key)
    }
    
    nonisolated func getStorageType() -> String {
        "UserDefaults"
    }
}
