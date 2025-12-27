import Foundation

/// Protocol for network client
public protocol NetworkClientProtocol: Sendable {
    func request(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
    func streamRequest(_ request: URLRequest) async throws -> AsyncThrowingStream<Data, Error>
}

/// Network client that handles all HTTP requests and responses
@available(iOS 18.0, macOS 15.0, *)
public actor NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let logger: NetworkLogger
    
    public init(session: URLSession = .shared, logger: NetworkLogger = DefaultNetworkLogger()) {
        self.session = session
        self.logger = logger
    }
    
    /// Send a regular HTTP request
    public func request(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        await logger.logRequest(request)
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await logger.logResponse(httpResponse, data: data, duration: duration)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            return (data, httpResponse)
        } catch let error as NetworkError {
            await logger.logError(error, for: request)
            throw error
        } catch {
            let networkError = NetworkError.networkFailure(error)
            await logger.logError(networkError, for: request)
            throw networkError
        }
    }
    
    /// Send a streaming HTTP request
    public func streamRequest(_ request: URLRequest) async throws -> AsyncThrowingStream<Data, Error> {
        await logger.logRequest(request)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.invalidResponse)
                        return
                    }
                    
                    await logger.logResponse(httpResponse, data: nil, duration: 0)
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: NetworkError.httpError(statusCode: httpResponse.statusCode, message: "Streaming failed"))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8) {
                            continuation.yield(data)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    await logger.logError(NetworkError.networkFailure(error), for: request)
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// Network errors
public enum NetworkError: LocalizedError, Sendable {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkFailure(Error)
    case invalidURL
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .networkFailure(let error):
            return "Network failure: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

/// Protocol for logging network requests and responses
public protocol NetworkLogger: Sendable {
    func logRequest(_ request: URLRequest) async
    func logResponse(_ response: HTTPURLResponse, data: Data?, duration: TimeInterval) async
    func logError(_ error: Error, for request: URLRequest) async
}

/// Default network logger implementation
public actor DefaultNetworkLogger: NetworkLogger {
    private let isEnabled: Bool
    
    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    public func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }
        
        print("🌐 → \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("   Headers: \(sanitizeHeaders(headers))")
        }
        
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("   Body: \(prettyString)")
        }
    }
    
    public func logResponse(_ response: HTTPURLResponse, data: Data?, duration: TimeInterval) {
        guard isEnabled else { return }
        
        let statusEmoji = (200...299).contains(response.statusCode) ? "✅" : "❌"
        print("\(statusEmoji) ← \(response.statusCode) (\(String(format: "%.2f", duration * 1000))ms)")
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("   Response: \(prettyString.prefix(500))")
        }
    }
    
    public func logError(_ error: Error, for request: URLRequest) {
        guard isEnabled else { return }
        
        print("❌ Error for \(request.url?.absoluteString ?? "unknown")")
        print("   \(error.localizedDescription)")
    }
    
    private func sanitizeHeaders(_ headers: [String: String]) -> [String: String] {
        var sanitized = headers
        if sanitized["Authorization"] != nil {
            sanitized["Authorization"] = "Bearer ***"
        }
        return sanitized
    }
}
