import ChatushSDK
import Factory
import Foundation
import SwiftUI

@MainActor
@Observable
final class LLMConfigurationViewModel {
    @ObservationIgnored
    @Injected(\.credentialsStorage)
    private var credentialsStorage

    var config: LLMProviderConfig
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    private let originalConfig: LLMProviderConfig
    private let onSave: (LLMProviderConfig) -> Void

    init(config: LLMProviderConfig, onSave: @escaping (LLMProviderConfig) -> Void) {
        self.config = config
        self.originalConfig = config
        self.onSave = onSave
    }
    
    func save() {
        onSave(config)
    }
    
    func cancel() -> Bool {
        // Return true if there are unsaved changes
        return config.name != originalConfig.name ||
               config.provider != originalConfig.provider ||
               config.model != originalConfig.model ||
               config.apiKey != originalConfig.apiKey ||
               config.endpoint != originalConfig.endpoint ||
               config.temperature != originalConfig.temperature ||
               config.maxTokens != originalConfig.maxTokens
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
