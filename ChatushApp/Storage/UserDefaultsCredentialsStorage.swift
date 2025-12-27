import Foundation

/// UserDefaults-based credentials storage implementation
final class UserDefaultsCredentialsStorage: CredentialsStorageProtocol, @unchecked Sendable {
    nonisolated init() {}

    private let key = "llm-configurations-data"
    private let userDefaults = UserDefaults.standard

    nonisolated func saveConfigurations(_ data: LLMConfigurationsData) async throws {
        let encoder = JSONEncoder()
        let jsonData = try await Task.detached {
            try encoder.encode(data)
        }
        .value
        userDefaults.set(jsonData, forKey: key)
    }

    nonisolated func loadConfigurations() async throws -> LLMConfigurationsData? {
        guard let jsonData = userDefaults.data(forKey: key) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try await Task.detached {
            try decoder.decode(LLMConfigurationsData.self, from: jsonData)
        }
        .value
    }

    nonisolated func deleteConfigurations() async throws {
        userDefaults.removeObject(forKey: key)
    }

    nonisolated func getStorageType() -> String {
        "UserDefaults"
    }
}
