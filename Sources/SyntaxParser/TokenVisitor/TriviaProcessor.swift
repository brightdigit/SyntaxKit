//
//  TriviaProcessor.swift
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
@_spi(RawSyntax) import SwiftSyntax

/// Utility for converting SwiftSyntax trivia pieces into string representations.
///
/// TriviaProcessor handles the conversion of all trivia types (whitespace, comments, etc.)
/// into their plain text equivalents, preserving the original formatting and content.
/// Trivia includes all the "invisible" elements around tokens that don't directly
/// participate in the Swift language grammar but are important for code reconstruction.
internal enum TriviaProcessor {
  /// Converts a SwiftSyntax trivia piece into its string representation.
  ///
  /// Trivia includes all the "invisible" elements around tokens: whitespace,
  /// comments, and other formatting. This method converts each type of trivia
  /// into plain text suitable for console output, preserving the original
  /// formatting and content.
  ///
  /// - Parameter piece: The trivia piece to convert
  /// - Returns: String representation of the trivia
  internal static func processTriviaPiece(_ piece: TriviaPiece) -> String {
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
      trivia += String(repeating: #"\"#, count: count)

    case .pounds(let count):
      // Handle pound characters (used in raw string literals and directives)
      trivia += String(repeating: "#", count: count)
    }

    return trivia
  }
}
