import ChatushSDK
import Factory
import SwiftData

/// Storage type preference
enum StorageType: String, CaseIterable {
    case keychain = "Keychain"
    case userDefaults = "UserDefaults"
}

/// Main dependency injection container using Factory
extension Container {

    var storageType: Factory<StorageType> {
        self { .keychain }
            .scope(.shared)
    }

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

    var networkClient: Factory<NetworkClientProtocol> {
        self { NetworkClient() }
            .scope(.singleton)
    }

    var chatushSDK: Factory<ChatushSDK> {
        self { 
            ChatushSDK(networkClient: self.networkClient())
        }
        .scope(.singleton)
    }

    var conversationsRepository: Factory<ConversationsRepositoryProtocol> {
        self {
            @MainActor in
            let context = self.modelContext()
            return ConversationsRepository(modelContext: context)
        }
        .scope(.singleton)
    }

    var modelContainer: Factory<ModelContainer> {
        self {
            let schema = Schema([
                Conversation.self,
                Message.self,
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
