import Factory
import SwiftData
import ChatushSDK

/// Storage type preference
enum StorageType: String, CaseIterable {
    case keychain = "Keychain"
    case userDefaults = "UserDefaults"
}

/// Main dependency injection container using Factory
extension Container {
    
    // MARK: - Storage Type
    
    var storageType: Factory<StorageType> {
        self { .keychain }
            .scope(.shared)
    }
    
    // MARK: - Credentials Storage
    
    var credentialsStorage: Factory<CredentialsStorageProtocol> {
        self {
            let type = self.storageType()
            switch type {
            case .keychain:
                return KeychainCredentialsStorage()
            case .userDefaults:
                return UserDefaultsCredentialsStorage()
            }
        }
        .scope(.singleton)
    }
    
    // MARK: - SDK
    
    var chatushSDK: Factory<ChatushSDK> {
        self { ChatushSDK() }
            .scope(.singleton)
    }
    
    // MARK: - Repositories
    
    var conversationsRepository: Factory<ConversationsRepositoryProtocol> {
        self {
            @MainActor in
            let context = self.modelContext()
            return ConversationsRepository(modelContext: context)
        }
        .scope(.singleton)
    }
    
    // MARK: - SwiftData Context
    
    var modelContainer: Factory<ModelContainer> {
        self {
            let schema = Schema([
                Conversation.self,
                Message.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
        .scope(.singleton)
    }
    
    var modelContext: Factory<ModelContext> {
        self {
            let container = self.modelContainer()
            return ModelContext(container)
        }
        .scope(.shared)
    }
}
