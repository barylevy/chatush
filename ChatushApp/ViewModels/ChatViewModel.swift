import ChatushSDK
import Factory
import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    @ObservationIgnored
    @Injected(\.conversationsRepository)
    private var repository

    @ObservationIgnored
    @Injected(\.chatushSDK)
    private var sdk

    @ObservationIgnored
    @Injected(\.credentialsStorage)
    private var credentialsStorage

    var conversation: Conversation?
    var messages: [Message] = []
    var inputText = ""
    var isLoading = false
    var isSending = false
    var errorMessage: String?
    var streamingMessage = ""
    var isStreaming = false
    var selectedMessages: Set<UUID> = []
    var isSelectionMode = false

    private var currentConfig: LLMProviderConfig?
    
    var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasSelectedMessages: Bool {
        !selectedMessages.isEmpty
    }

    func loadConversation(_ conversation: Conversation) async {
        self.conversation = conversation
        messages = conversation.messages.sorted { $0.timestamp < $1.timestamp }

        // Load config matching the conversation's provider and model
        await loadCurrentConfig()
    }
    
    private func loadCurrentConfig() async {
        guard let conversation else { return }
        
        do {
            if let configurationsData = try await credentialsStorage.loadConfigurations() {
                // Try to find a config matching the conversation's provider and model
                currentConfig = configurationsData.configurations.first { config in
                    config.provider == conversation.providerName &&
                    config.model == conversation.modelName
                }
                
                // Fallback to active config or default
                if currentConfig == nil {
                    currentConfig = configurationsData.activeConfig() ?? LLMProviderConfig.mockConfig
                }
            } else {
                currentConfig = LLMProviderConfig.mockConfig
            }
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            currentConfig = LLMProviderConfig.mockConfig
        }
    }

    func createNewConversation() async {
        do {
            if let configurationsData = try await credentialsStorage.loadConfigurations() {
                currentConfig = configurationsData.activeConfig()
            } else {
                currentConfig = LLMProviderConfig.mockConfig
            }
            
            guard let config = currentConfig else {
                currentConfig = LLMProviderConfig.mockConfig
                return
            }

            let newConversation = try await repository.createConversation(
                title: "New Chat",
                providerName: config.provider,
                modelName: config.model
            )
            conversation = newConversation
            messages = []
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
        }
    }

    func sendMessage() async {
        guard let conversation,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isSending else {
            return
        }

        let messageText = inputText
        inputText = ""
        isSending = true
        errorMessage = nil

        do {
            // Add user message
            let userMessage = try await repository.addMessage(
                to: conversation,
                content: messageText,
                isFromUser: true,
                latencyMs: nil
            )
            messages.append(userMessage)

            // Update title if this is the first message
            if messages.count == 1 {
                let title = String(messageText.prefix(50))
                conversation.title = title
                try await repository.updateConversation(conversation)
            }

            // Get config
            guard let config = currentConfig else {
                throw NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No configuration available"])
            }

            // Convert messages to SDK format
            let sdkMessages = messages.map { message in
                ChatMessage(
                    role: message.isFromUser ? .user : .assistant,
                    content: message.content
                )
            }

            // Create model configuration
            let modelConfig = ModelConfiguration(
                provider: config.provider,
                model: config.model,
                apiKey: config.apiKey,
                endpoint: config.endpoint,
                temperature: config.temperature,
                maxTokens: config.maxTokens
            )

            // Check if streaming is supported
            let supportsStreaming = await sdk.supportsStreaming(provider: config.provider)

            if supportsStreaming {
                // Use streaming
                isStreaming = true
                streamingMessage = ""

                let stream = await sdk.sendMessageStreaming(messages: sdkMessages, config: modelConfig)

                let startTime = Date()

                for try await chunk in stream {
                    streamingMessage += chunk
                }

                let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

                // Add assistant message
                let assistantMessage = try await repository.addMessage(
                    to: conversation,
                    content: streamingMessage,
                    isFromUser: false,
                    latencyMs: latencyMs
                )
                messages.append(assistantMessage)

                streamingMessage = ""
                isStreaming = false
            } else {
                // Use regular response
                let response = try await sdk.sendMessage(messages: sdkMessages, config: modelConfig)

                // Add assistant message
                let assistantMessage = try await repository.addMessage(
                    to: conversation,
                    content: response.text,
                    isFromUser: false,
                    latencyMs: response.latencyMs
                )
                messages.append(assistantMessage)
            }

        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            inputText = messageText // Restore input
        }

        isSending = false
    }

    func clearConversation() async {
        guard let conversation else { return }

        do {
            try await repository.clearConversation(conversation)
            messages.removeAll()
        } catch {
            errorMessage = "Failed to clear conversation: \(error.localizedDescription)"
        }
    }

    func deleteMessage(_ message: Message) async {
        guard let conversation else { return }

        do {
            try await repository.deleteMessage(message, from: conversation)
            messages.removeAll { $0.id == message.id }
        } catch {
            errorMessage = "Failed to delete message: \(error.localizedDescription)"
        }
    }

    func deleteMessages(_ messagesToDelete: [Message]) async {
        guard let conversation else { return }

        do {
            try await repository.deleteMessages(messagesToDelete, from: conversation)
            let messageIds = Set(messagesToDelete.map(\.id))
            messages.removeAll { messageIds.contains($0.id) }
        } catch {
            errorMessage = "Failed to delete messages: \(error.localizedDescription)"
        }
    }

    func switchProvider(newConfig: LLMProviderConfig) async {
        guard let conversation else { return }

        currentConfig = newConfig
        conversation.providerName = newConfig.provider
        conversation.modelName = newConfig.model

        do {
            try await repository.updateConversation(conversation)
        } catch {
            errorMessage = "Failed to update provider: \(error.localizedDescription)"
        }
    }
    
    func updateConfiguration(_ newConfig: LLMProviderConfig) async {
        currentConfig = newConfig
        
        guard let conversation else { return }
        
        conversation.providerName = newConfig.provider
        conversation.modelName = newConfig.model
        
        do {
            try await repository.updateConversation(conversation)
        } catch {
            errorMessage = "Failed to update provider: \(error.localizedDescription)"
        }
    }
    
    func conversationExists(_ conversation: Conversation) async -> Bool {
        do {
            let fetchedConversation = try await repository.fetchConversation(id: conversation.id)
            return fetchedConversation != nil
        } catch {
            return false
        }
    }
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedMessages.removeAll()
        }
    }
    
    func toggleMessageSelection(_ messageId: UUID) {
        if selectedMessages.contains(messageId) {
            selectedMessages.remove(messageId)
        } else {
            selectedMessages.insert(messageId)
        }
    }
    
    func deleteSelectedMessages() async {
        let messagesToDelete = messages.filter { selectedMessages.contains($0.id) }
        await deleteMessages(messagesToDelete)
        selectedMessages.removeAll()
        isSelectionMode = false
    }
}
