//
//  CommentBuilderResult.swift
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

/// A result builder for creating arrays of ``Line``s for comments.
@resultBuilder
public enum CommentBuilderResult: Sendable, Equatable {
  /// Builds a block of ``Line``s.
  public static func buildBlock(_ components: Line...) -> [Line] { components }
}

// MARK: - Public DSL surface

extension CodeBlock {
  /// Attaches comments to the current ``CodeBlock``.
  ///
  /// The provided lines are injected as leading trivia to the declaration produced by this ``CodeBlock``.
  ///
  /// Usage:
  /// ```swift
  /// Struct("MyStruct") { ... }
  ///   .comment {
  ///       Line("MARK: - Models")
  ///       Line(.doc, "This is a documentation comment")
  ///   }
  /// ```
  /// - Parameter content: A ``CommentBuilderResult`` that provides the comment lines.
  /// - Returns: A new ``CodeBlock`` with the comments attached.
  public func comment(@CommentBuilderResult _ content: () -> [Line]) -> any CodeBlock {
    CommentedCodeBlock(base: self, lines: content())
  }
}
