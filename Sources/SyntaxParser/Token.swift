//
//  Token.swift
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

import Foundation

/// Represents metadata for a terminal token in the syntax tree.
///
/// Token contains detailed information about leaf nodes in the AST,
/// including the token's classification and associated trivia (whitespace,
/// comments, etc.). This information is essential for understanding the
/// exact structure and formatting of the original source code.
///
/// Trivia includes all the "invisible" text around tokens like spaces,
/// newlines, comments, and other formatting elements that don't directly
/// participate in the Swift language grammar but are important for
/// code reconstruction and analysis.
internal struct Token: Codable, Equatable {
  /// The classification of this token (e.g., "keyword", "identifier", "integerLiteral").
  /// Corresponds to SwiftSyntax TokenKind descriptions.
  internal let kind: String

  /// Trivia that appears before this token.
  /// Includes whitespace, comments, and other non-semantic text preceding the token.
  internal var leadingTrivia: String

  /// Trivia that appears after this token.
  /// Includes whitespace, comments, and other non-semantic text following the token.
  internal var trailingTrivia: String

  /// Creates a new Token with the specified properties.
  ///
  /// - Parameters:
  ///   - kind: The token classification
  ///   - leadingTrivia: Text appearing before the token
  ///   - trailingTrivia: Text appearing after the token
  internal init(kind: String, leadingTrivia: String, trailingTrivia: String) {
    self.kind = kind
    self.leadingTrivia = leadingTrivia
    self.trailingTrivia = trailingTrivia
  }
}
