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
    @Injected(\.conversationsRepository)
    private var conversationsRepository

    @ObservationIgnored
    @Injected(\.storageType)
    private var storageTypeFactory

    var configurationsData: LLMConfigurationsData = .default
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var storageType: StorageType = .keychain

    func loadConfigurations() async {
        isLoading = true
        errorMessage = nil

        do {
            if let loadedData = try await credentialsStorage.loadConfigurations() {
                configurationsData = loadedData
            } else {
                configurationsData = .default
            }
            storageType = storageTypeFactory
        } catch {
            errorMessage = "Failed to load configurations: \(error.localizedDescription)"
            configurationsData = .default
        }

        isLoading = false
    }

    func saveConfigurations() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await credentialsStorage.saveConfigurations(configurationsData)
            successMessage = "Configurations saved successfully"
        } catch {
            errorMessage = "Failed to save configurations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateConfiguration(_ config: LLMProviderConfig) {
        if let index = configurationsData.configurations.firstIndex(where: { $0.id == config.id }) {
            configurationsData.configurations[index] = config
        }

        Task {
            await saveConfigurations()
        }
    }

    func setActiveConfiguration(_ id: UUID) {
        configurationsData.activeConfigId = id

        Task {
            await saveConfigurations()
        }
    }

    func deleteConfigurations() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await credentialsStorage.deleteConfigurations()
            configurationsData = .default
            successMessage = "Configurations reset successfully"
        } catch {
            errorMessage = "Failed to delete configurations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func changeStorageType(_ newType: StorageType) {
        storageType = newType
        Container.shared.storageType.register { newType }
        Container.shared.credentialsStorage.reset()

        Task {
            await loadConfigurations()
        }
    }
    
    func clearAllData() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await conversationsRepository.clearAllConversations()
            successMessage = "All conversations deleted successfully"
        } catch {
            errorMessage = "Failed to clear conversations: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
