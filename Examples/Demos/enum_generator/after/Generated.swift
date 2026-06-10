// MARK: - Generated API Enums
// ⚡ Auto-generated from api-config.json using SyntaxKit
// ✅ Always synchronized with backend configuration
// 🚀 Generated on: 2025-09-01T19:15:30Z

/// API endpoints for the application
/// 
/// ⚡ Generated automatically from api-config.json
/// ✅ Always synchronized with backend configuration
public enum APIEndpoint: String, CaseIterable {
    case analytics = "/api/v2/analytics"
    case comments = "/api/v2/comments"
    case notifications = "/api/v2/notifications"
    case posts = "/api/v2/posts"
    case search = "/api/v2/search"
    case userProfile = "/api/v2/users/{id}"
    case users = "/api/v2/users"
}

/// HTTP status codes for API responses
/// 
/// ⚡ Generated automatically from api-config.json
/// ✅ Complete coverage of all backend status codes
public enum HTTPStatus: Int, CaseIterable {
    case success = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalError = 500
    case serviceUnavailable = 503
}

/// Network errors that can occur during API calls
/// 
/// ⚡ Generated automatically from api-config.json
/// ✅ Perfect structural match with backend error format
public enum NetworkError: Error, Equatable {
    case invalidURL(url: String)
    case httpError(statusCode: Int, message: String)
    case networkUnavailable
    case decodingError(DecodingError)
}