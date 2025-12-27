import Foundation

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

        let statusEmoji = (200 ... 299).contains(response.statusCode) ? "✅" : "❌"
        print("\(statusEmoji) ← \(response.statusCode) (\(String(format: "%.2f", duration * 1000))ms)")

        if let data,
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
