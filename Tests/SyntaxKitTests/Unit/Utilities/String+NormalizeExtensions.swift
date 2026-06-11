//
//  String+NormalizeExtensions.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

extension String {
  /// Normalize whitespace and formatting for code comparison
  /// - Parameter options: Normalization options to control formatting preservation
  /// - Returns: Normalized string
  internal func normalize(options: NormalizeOptions = .default) -> String {
    var result = self

    // Always normalize colon spacing
    result = result.replacingOccurrences(of: "\\s*:\\s*", with: ": ", options: .regularExpression)

    if options.contains(.preserveSiblingNewlines) {
      // For SwiftUI, preserve newlines between sibling views but normalize other whitespace
      // Replace multiple spaces with single space, but keep newlines
      result = result.replacingOccurrences(of: "[ ]+", with: " ", options: .regularExpression)

      // Normalize newlines to single newlines
      result = result.replacingOccurrences(of: "\\n+", with: "\n", options: .regularExpression)

      // Remove leading/trailing whitespace but preserve internal structure
      result = result.trimmingCharacters(in: .whitespacesAndNewlines)

      // For SwiftUI, ensure consistent spacing around method chaining
      // Add space after closing braces before method calls
      result = result.replacingOccurrences(of: "}\\.", with: "} .", options: .regularExpression)

      // Ensure consistent spacing in ternary operators
      result = result.replacingOccurrences(of: "\\?\\s*:", with: "? :", options: .regularExpression)

      // Add newlines between sibling views (Button elements)
      result = result.replacingOccurrences(
        of: "}\\s*Button",
        with: "}\\nButton",
        options: .regularExpression
      )

      // Add newline after method chaining
      result = result.replacingOccurrences(
        of: "\\.foregroundColor\\([^)]*\\)\\s*}",
        with: ".foregroundColor($1)\\n}",
        options: .regularExpression
      )

      // Normalize Task closure formatting
      result = result.replacingOccurrences(
        of: "Task\\s*{\\s*@MainActor",
        with: "Task { @MainActor",
        options: .regularExpression
      )
    } else if options.contains(.preserveBraceNewlines) {
      // Preserve newlines after braces but normalize other whitespace
      result = result.replacingOccurrences(of: "[ ]+", with: " ", options: .regularExpression)
      result = result.replacingOccurrences(of: "\\n+", with: "\n", options: .regularExpression)
      result = result.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      // Default behavior: normalize all whitespace including newlines
      result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      result = result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return result
  }

  /// Legacy normalize function for backward compatibility
  internal func normalize() -> String {
    normalize(options: .default)
  }

  /// Structural comparison - removes all whitespace and formatting differences
  /// Useful for comparing code structure without caring about formatting
  internal func normalizeStructural() -> String {
    self
      .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  /// Flexible comparison - allows for minor formatting differences
  /// Useful for tests that should be resilient to formatting changes
  internal func normalizeFlexible() -> String {
    self
      .replacingOccurrences(
        of: "\\s*:\\s*",
        with: ":",
        options: .regularExpression
      )  // Normalize colons
      .replacingOccurrences(
        of: "\\s*=\\s*",
        with: "=",
        options: .regularExpression
      )  // Normalize equals
      .replacingOccurrences(
        of: "\\s*->\\s*",
        with: "->",
        options: .regularExpression
      )  // Normalize arrows
      .replacingOccurrences(
        of: "\\s*,\\s*",
        with: ",",
        options: .regularExpression
      )  // Normalize commas
      .replacingOccurrences(
        of: "\\s*\\(\\s*",
        with: "(",
        options: .regularExpression
      )  // Normalize opening parens
      .replacingOccurrences(
        of: "\\s*\\)\\s*",
        with: ")",
        options: .regularExpression
      )  // Normalize closing parens
      .replacingOccurrences(
        of: "\\s*{\\s*",
        with: "{",
        options: .regularExpression
      )  // Normalize opening braces
      .replacingOccurrences(
        of: "\\s*}\\s*",
        with: "}",
        options: .regularExpression
      )  // Normalize closing braces
      .replacingOccurrences(
        of: "\\s+",
        with: "",
        options: .regularExpression
      )  // Remove remaining whitespace
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
