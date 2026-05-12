# Enum Generator: Before vs After SyntaxKit

This example demonstrates the power of SyntaxKit for dynamic Swift code generation by showing a real-world scenario where enum maintenance becomes automated.

## Scenario: API Configuration Management

Imagine you're building an iOS app that needs to manage API endpoints. As your API evolves, you need to keep your Swift enums in sync with the server configuration.

## The Problem: Manual Enum Maintenance

### Before SyntaxKit (Manual Approach)

**Step 1**: Your backend team updates the API configuration in `api-config.json`:
```json
{
  "endpoints": {
    "users": "/api/v2/users",
    "posts": "/api/v2/posts", 
    "comments": "/api/v2/comments",
    "userProfile": "/api/v2/users/{id}",
    "analytics": "/api/v2/analytics"
  },
  "statusCodes": {
    "success": 200,
    "created": 201, 
    "badRequest": 400,
    "unauthorized": 401,
    "forbidden": 403,
    "notFound": 404,
    "internalError": 500,
    "serviceUnavailable": 503
  }
}
```

**Step 2**: You manually update your Swift enums:
```swift
// APIEndpoint.swift - Updated manually ❌
public enum APIEndpoint: String, CaseIterable {
    case users = "/api/v2/users"
    case posts = "/api/v2/posts" 
    case comments = "/api/v2/comments"
    case userProfile = "/api/v2/users/{id}"
    case analytics = "/api/v2/analytics"  // ← Added manually
}

// HTTPStatus.swift - Updated manually ❌  
public enum HTTPStatus: Int, CaseIterable {
    case success = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalError = 500
    case serviceUnavailable = 503  // ← Added manually
}
```

**Problems with this approach:**
- ❌ Manual process prone to human error
- ❌ Easy to forget updating Swift code when API changes
- ❌ No validation that Swift enums match server configuration
- ❌ Time-consuming for large APIs with many endpoints
- ❌ Version drift between backend config and iOS enums

## The Solution: Automated Generation with SyntaxKit

### After SyntaxKit (Automated Approach)

**Step 1**: Same API configuration update in `api-config.json` ✅

**Step 2**: Run the automated generator:
```bash
swift run enum-generator api-config.json Sources/Generated/
```

**Step 3**: Perfect Swift enums generated automatically:
```swift
// Generated/APIEndpoints.swift - Generated automatically ✅
/// API endpoints for the application
/// 
/// Use this enum to ensure type-safe API endpoint references
public enum APIEndpoint: String, CaseIterable {
    case users = "/api/v2/users"
    case posts = "/api/v2/posts"
    case comments = "/api/v2/comments"
    case userProfile = "/api/v2/users/{id}"
    case analytics = "/api/v2/analytics"  // ← Added automatically
}

// Generated/HTTPStatus.swift - Generated automatically ✅
/// HTTP status codes for API responses
public enum HTTPStatus: Int, CaseIterable {
    case success = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalError = 500
    case serviceUnavailable = 503  // ← Added automatically
}
```

**Benefits of this approach:**
- ✅ Zero manual Swift code updates needed
- ✅ Guaranteed synchronization with backend configuration
- ✅ Automatic validation and error detection
- ✅ Scales to hundreds of endpoints effortlessly
- ✅ No version drift possible
- ✅ Can be integrated into CI/CD pipeline

## Files in This Example

- `before/` - Manual approach with prone-to-error maintenance
- `after/` - SyntaxKit-powered automated generation  
- `api-config.json` - Example API configuration
- `dsl.swift` - SyntaxKit generator implementation
- `main.swift` - CLI tool for running the generator
- `generate.swift` - Generation helper script

## Run the Example

```bash
# Generate enums from configuration
swift run enum-generator-example

# See the generated code
cat code.swift
```

This demonstrates how SyntaxKit transforms tedious, error-prone manual processes into reliable, automated code generation.