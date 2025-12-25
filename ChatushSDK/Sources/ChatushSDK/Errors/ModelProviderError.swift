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
            return "API key is required for this provider"
        case .invalidEndpoint:
            return "Invalid endpoint URL"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from provider"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .unsupportedProvider(let provider):
            return "Unsupported provider: \(provider)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
