//
//  TokenVisitor+Helpers.swift
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
import SwiftSyntax

/// Extension providing helper methods for token and trivia processing.
///
/// This extension contains utility functions that support the main TokenVisitor
/// functionality by handling the detailed processing of individual tokens and
/// their associated trivia (whitespace, comments, etc.).
extension TokenVisitor {
  // MARK: - String Constants

  /// Character used to identify token kind parameter lists in string representations.
  private static let openParen: Character = "("

  /// Suffix used by SwiftSyntax keyword token kinds.
  private static let keyword = "Keyword"

  /// Normalized name for keyword tokens in output.
  private static let keywordNormalized = "keyword"

  /// @available(*, unavailable) HTML formatting constants (deprecated for console output).
  /// These constants remain for potential future web-based usage but are not used
  /// in the current plain-text console output implementation.
  private static let spanClass = "<span class='"
  private static let spanEnd = "</span>"
  private static let dataTitle = "data-title='"
  private static let dataContent = "data-content='"
  private static let dataType = "data-type='"
  private static let trivia = "Trivia"
  private static let nonBreakingSpace = "&nbsp;"
  private static let lineBreak = "<br/>"
  private static let lineComment = "lineComment"
  private static let blockComment = "blockComment"
  private static let docLineComment = "docLineComment"
  private static let docBlockComment = "docBlockComment"
  private static let unexpectedText = "unexpectedText"

  /// Characters used in Swift syntax for specific purposes.
  private static let backslash = #"\"#
  private static let pound = "#"

  /// Multiplier for converting tabs to equivalent spaces (deprecated for console output).
  private static let whitespaceSpacer = 2

  // MARK: - Token Processing

  /// Processes a token for additional metadata extraction.
  ///
  /// This method performs token-specific processing that was originally used
  /// for HTML output generation. In the current console-focused implementation,
  /// most of this processing is no longer needed, but the method is retained
  /// for potential future enhancements.
  ///
  /// - Parameter token: The token to process
  internal func processToken(_ token: TokenSyntax) {
    // Clean up token kind string representation
    var kind = "\(token.tokenKind)"
    if let index = kind.firstIndex(of: Self.openParen) {
      kind = String(kind.prefix(upTo: index))
    }
    if kind.hasSuffix(Self.keyword) {
      kind = Self.keywordNormalized
    }

    // Legacy processing - no longer needed for plain text output
    // These operations were used for HTML generation but are now minimal
    _ = token.sourceRange(converter: locationConverter)
    _ = token.presence == .present || showMissingTokens ? token.text : TokenVisitor.emptyString
  }

  // MARK: - Trivia Processing

  /// Converts a SwiftSyntax trivia piece into its string representation.
  ///
  /// Trivia includes all the \"invisible\" elements around tokens: whitespace,
  /// comments, and other formatting. This method converts each type of trivia
  /// into plain text suitable for console output, preserving the original
  /// formatting and content.
  ///
  /// - Parameter piece: The trivia piece to convert
  /// - Returns: String representation of the trivia
  internal func processTriviaPiece(_ piece: TriviaPiece) -> String {
    var trivia = TokenVisitor.emptyString

    switch piece {
    case .spaces(let count):
      // Convert spaces to actual space characters
      trivia += String(repeating: " ", count: count)

    case .tabs(let count):
      // Convert tabs to actual tab characters
      trivia += String(repeating: "\t", count: count)

    case .verticalTabs, .formfeeds:
      // Ignore legacy whitespace characters
      break

    case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
      // Convert line endings to newline characters
      trivia += String(repeating: "\n", count: count)

    case .lineComment(let text):
      // Preserve line comments as-is
      trivia += text

    case .blockComment(let text):
      // Preserve block comments as-is
      trivia += text

    case .docLineComment(let text):
      // Preserve documentation line comments as-is
      trivia += text

    case .docBlockComment(let text):
      // Preserve documentation block comments as-is
      trivia += text

    case .unexpectedText(let text):
      // Preserve unexpected text (usually from parsing errors)
      trivia += text

    case .backslashes(let count):
      // Handle backslash characters (used in string literals and escaping)
      trivia += String(repeating: Self.backslash, count: count)

    case .pounds(let count):
      // Handle pound characters (used in raw string literals and directives)
      trivia += String(repeating: Self.pound, count: count)
    }

    return trivia
  }
}
