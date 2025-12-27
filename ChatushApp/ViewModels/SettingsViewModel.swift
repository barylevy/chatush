import ChatushSDK
import Factory
import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored
    @Injected(\.credentialsStorage)
    private var credentialsStorage

    @ObservationIgnored
    @Injected(\.storageType)
    private var storageTypeFactory

    var config: LLMProviderConfig = .defaultConfig
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var storageType: StorageType = .keychain

    func loadConfig() async {
        isLoading = true
        errorMessage = nil

        do {
            if let loadedConfig = try await credentialsStorage.loadConfig() {
                config = loadedConfig
            } else {
                config = .defaultConfig
            }
            storageType = storageTypeFactory
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            config = .defaultConfig
        }

        isLoading = false
    }

    func saveConfig() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await credentialsStorage.saveConfig(config)
            successMessage = "Configuration saved successfully"
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteConfig() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await credentialsStorage.deleteConfig()
            config = .defaultConfig
            successMessage = "Configuration deleted successfully"
        } catch {
            errorMessage = "Failed to delete configuration: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func changeStorageType(_ newType: StorageType) {
        storageType = newType
        Container.shared.storageType.register { newType }
        Container.shared.credentialsStorage.reset()

        Task {
            await loadConfig()
        }
    }

    func testConnection() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let sdk = Container.shared.chatushSDK()
            let testMessage = ChatMessage(role: .user, content: "Hello")

            let modelConfig = ModelConfiguration(
                provider: config.provider,
                model: config.model,
                apiKey: config.apiKey,
                endpoint: config.endpoint,
                temperature: config.temperature,
                maxTokens: config.maxTokens
            )

            _ = try await sdk.sendMessage(messages: [testMessage], config: modelConfig)
            successMessage = "Connection successful!"
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
