import Foundation

/// Errors that can occur when using model providers
public enum ModelProviderError: LocalizedError, Sendable {
    case missingApiKey
    case invalidEndpoint
    case invalidRequest
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case unsupportedProvider(String)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            "API key is required for this provider"
        case .invalidEndpoint:
            "Invalid endpoint URL"
        case .invalidRequest:
            "Invalid request format"
        case .invalidResponse:
            "Invalid response from provider"
        case .apiError(let statusCode, let message):
            "API Error (\(statusCode)): \(message)"
        case .unsupportedProvider(let provider):
            "Unsupported provider: \(provider)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
