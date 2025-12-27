import Factory
import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatSettingsViewModel {
    @ObservationIgnored
    @Injected(\.conversationsRepository)
    private var repository
    
    @ObservationIgnored
    @Injected(\.credentialsStorage)
    private var credentialsStorage
    
    var currentConfig: LLMProviderConfig?
    var errorMessage: String?
    var editedTitle: String = ""
    
    var isTitleValid: Bool {
        !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func loadConfiguration(for conversation: Conversation) async {
        editedTitle = conversation.title
        
        do {
            guard let configurationsData = try await credentialsStorage.loadConfigurations() else {
                // No configurations saved, use defaults
                currentConfig = conversation.providerName == "mock" 
                    ? LLMProviderConfig.mockConfig 
                    : LLMProviderConfig.openAIConfig
                return
            }
            
            // Find configuration matching the conversation's provider and model
            currentConfig = configurationsData.configurations.first { config in
                config.provider == conversation.providerName && 
                config.model == conversation.modelName
            }
            
            // If no match found, use active configuration or default
            if currentConfig == nil {
                currentConfig = configurationsData.activeConfig() ?? LLMProviderConfig.mockConfig
            }
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            currentConfig = LLMProviderConfig.mockConfig
        }
    }
    
    func updateConfiguration(_ config: LLMProviderConfig, for conversation: Conversation) async {
        conversation.providerName = config.provider
        conversation.modelName = config.model
        currentConfig = config
        
        do {
            try await repository.updateConversation(conversation)
        } catch {
            errorMessage = "Failed to update conversation: \(error.localizedDescription)"
        }
    }
    
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await repository.deleteConversation(conversation)
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    func saveTitle(for conversation: Conversation) async {
        guard isTitleValid else { return }
        
        conversation.title = editedTitle
        
        do {
            try await repository.updateConversation(conversation)
        } catch {
            errorMessage = "Failed to save title: \(error.localizedDescription)"
        }
    }
}
