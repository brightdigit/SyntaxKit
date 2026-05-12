// HTTPStatus.swift - Manual maintenance approach
// ❌ Manually maintained, incomplete coverage

import Foundation

/// HTTP status codes 
/// ⚠️ WARNING: Only covers basic status codes, missing many standard ones
public enum HTTPStatus: Int, CaseIterable {
    case success = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401  
    case notFound = 404
    case internalError = 500
    // ❌ Missing: forbidden (403), serviceUnavailable (503)
    // ❌ Developer only added status codes as needed, incomplete set
}

// MARK: - Additional Problems:
/*
 Issues with manual HTTP status enum:
 
 1. INCOMPLETE COVERAGE: Missing forbidden (403), serviceUnavailable (503)
 2. INCONSISTENT NAMING: Some call it "success", others call it "ok"
 3. NO STANDARDIZATION: Different developers add codes differently
 4. MISSING DOCUMENTATION: No explanation of when to use each code
 5. STATIC LIST: Can't easily adapt to API-specific status codes
 
 When the backend starts returning 503 Service Unavailable errors,
 the iOS app has no enum case to handle it properly.
 */