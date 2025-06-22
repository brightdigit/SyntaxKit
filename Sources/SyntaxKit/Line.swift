//
//  Line.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import SwiftSyntax

/// Represents a single comment line that can be attached to a syntax node.
public struct Line {
  /// The kind of comment line.
  public enum Kind {
    /// Regular line comment that starts with `//`.
    case line
    /// Documentation line comment that starts with `///`.
    case doc
  }

  /// The kind of comment.
  public let kind: Kind
  /// The text of the comment.
  public let text: String?

  /// Creates a regular line comment.
  /// - Parameter text: The text of the comment.
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
  /// - Parameters:
  ///   - kind: The kind of comment. Defaults to `.line`.
  ///   - text: The text of the comment. Defaults to `nil`.
  public init(_ kind: Kind = .line, _ text: String? = nil) {
    self.kind = kind
    self.text = text
  }
}

// MARK: - Internal helpers

extension Line {
  /// Convert the `Line` to a SwiftSyntax `TriviaPiece`.
  internal var triviaPiece: TriviaPiece {
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
