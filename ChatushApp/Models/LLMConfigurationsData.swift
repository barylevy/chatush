import Foundation

/// Container for all configurations and the active one
struct LLMConfigurationsData: Codable, Sendable {
    var configurations: [LLMProviderConfig]
    var activeConfigId: UUID

    static let `default` = LLMConfigurationsData(
        configurations: LLMProviderConfig.defaultConfigs,
        activeConfigId: LLMProviderConfig.mockConfig.id
    )

    func activeConfig() -> LLMProviderConfig? {
        configurations.first { $0.id == activeConfigId }
    }
}
