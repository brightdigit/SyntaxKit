// NetworkError.swift - Manual maintenance approach
// ❌ Inconsistent with backend error specifications

import Foundation

/// Network errors that can occur during API calls
/// ⚠️ WARNING: This enum structure doesn't match backend error format
public enum NetworkError: Error {
    case badURL                           // ❌ Backend calls this "invalidURL"
    case httpFailure(Int)                 // ❌ Backend sends statusCode + message
    case offline                          // ❌ Backend calls this "networkUnavailable" 
    case parseError                       // ❌ Backend sends specific DecodingError
}

// MARK: - Synchronization Problems:
/*
 Issues with manual NetworkError enum:
 
 1. NAMING INCONSISTENCY: 
    - iOS: "badURL" vs Backend: "invalidURL"
    - iOS: "offline" vs Backend: "networkUnavailable"
    - iOS: "parseError" vs Backend: "decodingError"
 
 2. STRUCTURE MISMATCH:
    - iOS: httpFailure(Int) 
    - Backend: httpError(statusCode: Int, message: String)
 
 3. MISSING ERROR CONTEXT:
    - iOS parseError has no details
    - Backend decodingError includes full DecodingError
 
 4. NO VALIDATION: No way to verify this matches backend error spec
 
 5. EVOLUTION PROBLEMS: When backend adds new error types,
    iOS enum becomes incomplete
 
 This leads to poor error handling where the iOS app can't properly
 parse or display backend error responses.
 */