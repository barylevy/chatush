import Foundation
import SwiftUI
import Factory

@MainActor
@Observable
final class HistoryViewModel {
    
    @ObservationIgnored
    @Injected(\.conversationsRepository) private var repository
    
    var conversations: [Conversation] = []
    var isLoading = false
    var errorMessage: String?
    
    private let pageSize = 20
    private var currentOffset = 0
    private var hasMorePages = true
    
    func loadInitialConversations() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMorePages = true
        
        do {
            conversations = try await repository.fetchConversations(limit: pageSize, offset: 0)
            hasMorePages = conversations.count == pageSize
            currentOffset = conversations.count
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMoreConversations() async {
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        
        do {
            let newConversations = try await repository.fetchConversations(limit: pageSize, offset: currentOffset)
            conversations.append(contentsOf: newConversations)
            hasMorePages = newConversations.count == pageSize
            currentOffset += newConversations.count
        } catch {
            errorMessage = "Failed to load more conversations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await repository.deleteConversation(conversation)
            conversations.removeAll { $0.id == conversation.id }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    func refreshConversations() async {
        await loadInitialConversations()
    }
}
