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
