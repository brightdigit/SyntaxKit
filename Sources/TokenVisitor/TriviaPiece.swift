//
//  TriviaPiece.swift
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

// MARK: - TriviaPiece Extension

extension TriviaPiece {
  /// Represents the different ways a trivia piece can be processed.
  private enum ProcessedTrivia {
    case repeating(String, count: Int)
    case text(String)
  }

  /// Converts this trivia piece into a ProcessedTrivia enum, returning nil for empty cases.
  ///
  /// - Returns: ProcessedTrivia enum if the piece has content, nil for empty cases
  private var processedTrivia: ProcessedTrivia? {
    switch self {
    // Text Cases (preserve text as-is)
    case .lineComment(let text),
      .blockComment(let text),
      .docLineComment(let text),
      .docBlockComment(let text),
      .unexpectedText(let text):
      return .text(text)

    // Repeating Value Cases (repeat characters based on count)
    case .spaces(let count):
      return .repeating(" ", count: count)

    case .tabs(let count):
      return .repeating("\t", count: count)

    case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
      return .repeating("\n", count: count)

    case .backslashes(let count):
      return .repeating(#"\"#, count: count)

    case .pounds(let count):
      return .repeating("#", count: count)

    // Empty Cases (ignore/no-op) - return nil
    case .verticalTabs, .formfeeds:
      return nil
    }
  }

  /// Converts this trivia piece into its string representation using ProcessedTrivia.
  ///
  /// - Returns: String representation of the trivia, empty string for empty cases
  internal var processedString: String {
    guard let processed = processedTrivia else {
      return ""
    }

    switch processed {
    case .text(let text):
      return text
    case .repeating(let character, let count):
      return String(repeating: character, count: count)
    }
  }
}
