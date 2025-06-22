//
//  Line.swift
//  Lint
//
//  Created by Leo Dion on 6/16/25.
//

/// Represents a single comment line that can be attached to a syntax node when using 
/// `.comment { ... }` in the DSL.
public struct Line {
  public enum Kind {
    /// Regular line comment that starts with `//`.
    case line
    /// Documentation line comment that starts with `///`.
    case doc
  }

  public let kind: Kind
  public let text: String?

  /// Convenience initializer for a regular line comment without specifying the kind explicitly.
  public init(_ text: String) {
    self.kind = .line
    self.text = text
  }

  /// Convenience initialiser. Passing only `kind` will create an empty comment line of that kind.
  ///
  /// Examples:
  /// ```swift
  /// Line("MARK: - Models")              // defaults to `.line` kind
  /// Line(.doc, "Represents a model")    // documentation comment
  /// Line(.doc)                           // empty `///` line
  /// ```
  public init(_ kind: Kind = .line, _ text: String? = nil) {
    self.kind = kind
    self.text = text
  }
}

// MARK: - Internal helpers

extension Line {
  /// Convert the `Line` to a SwiftSyntax `TriviaPiece`.
  fileprivate var triviaPiece: TriviaPiece {
    switch kind {
    case .line:
      return .lineComment("// " + (text ?? ""))
    case .doc:
      // Empty doc line should still contain the comment marker so we keep a single `/` if no text.
      if let text = text, !text.isEmpty {
        return .docLineComment("/// " + text)
      } else {
        return .docLineComment("///")
      }
    }
  }
}
