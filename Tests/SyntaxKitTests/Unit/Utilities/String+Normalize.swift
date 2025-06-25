import Foundation

/// Options for string normalization
public struct NormalizeOptions: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Preserve newlines between sibling elements (useful for SwiftUI)
  public static let preserveSiblingNewlines = NormalizeOptions(rawValue: 1 << 0)

  /// Preserve newlines after braces
  public static let preserveBraceNewlines = NormalizeOptions(rawValue: 1 << 1)

  /// Preserve indentation structure
  public static let preserveIndentation = NormalizeOptions(rawValue: 1 << 2)

  /// Default options for general code comparison
  public static let `default`: NormalizeOptions = []

  /// Options for SwiftUI code that needs to preserve some formatting
  public static let swiftUI: NormalizeOptions = [.preserveSiblingNewlines, .preserveBraceNewlines]

  /// Options for structural comparison (ignores all formatting)
  public static let structural: NormalizeOptions = []
}

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
