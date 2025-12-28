import ChatushSDK
import Factory

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
    
    var fileStorageManager: Factory<FileStorageManagerProtocol> {
        self { FileStorageManager() }
            .scope(.singleton)
    }

    var conversationsRepository: Factory<ConversationsRepositoryProtocol> {
        self {
            @MainActor in
            let storage = self.fileStorageManager()
            return ConversationsRepository(storage: storage)
        }
        .scope(.singleton)
    }
}
