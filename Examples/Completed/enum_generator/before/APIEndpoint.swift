// APIEndpoint.swift - Manual maintenance approach
// Last updated: 2025-08-15 (3 weeks ago!)
// ❌ This file is manually maintained and often gets out of sync

import Foundation

/// API endpoints for the application
/// 
/// ⚠️ WARNING: Remember to update this enum when backend API changes!
/// ⚠️ Last sync with api-config.json: Unknown
public enum APIEndpoint: String, CaseIterable {
    case users = "/api/v1/users"        // ❌ Still v1, should be v2
    case posts = "/api/v2/posts"        // ✅ Correct
    case comments = "/api/v2/comments"  // ✅ Correct  
    case userProfile = "/api/v2/users/{id}"  // ✅ Correct
    // ❌ Missing: analytics, search, notifications endpoints
    // ❌ Developer forgot to add new endpoints from latest API update
}

// MARK: - Problems with manual approach:
/*
 Issues discovered in this file:
 
 1. VERSION MISMATCH: users endpoint still points to v1 instead of v2
 2. MISSING ENDPOINTS: analytics, search, notifications endpoints not added
 3. NO VALIDATION: No way to verify this matches server configuration
 4. MANUAL PROCESS: Developers forget to update when API changes
 5. STALE DOCUMENTATION: Comments don't indicate last sync date
 6. HUMAN ERROR: Easy to make typos in endpoint URLs
 
 This leads to runtime failures when the iOS app tries to hit endpoints
 that don't exist or uses wrong API versions.
 */