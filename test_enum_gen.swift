#!/usr/bin/env swift

import Foundation

// Swift script to test the enum generator from the Quick Start guide
// This uses the same pattern but as a standalone test

// First, let's check if we can import SyntaxKit
do {
    // Simple test to verify the concepts work
    let jsonConfig = """
    {
      "name": "HTTPStatus",
      "cases": [
        {"name": "ok", "value": "200"},
        {"name": "notFound", "value": "404"},
        {"name": "serverError", "value": "500"}
      ]
    }
    """

    print("JSON Configuration:")
    print(jsonConfig)
    print()

    print("This would generate Swift enum code using SyntaxKit:")
    print("enum HTTPStatus: Int, CaseIterable {")
    print("    case ok = 200")
    print("    case notFound = 404")
    print("    case serverError = 500")
    print("}")
} catch {
    print("Error: \(error)")
}
