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

extension TokenVisitor {
  // Constants for token processing and HTML generation
  private static let openParen: Character = "("
  private static let keyword = "Keyword"
  private static let keywordNormalized = "keyword"
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
  private static let backslash = #"\"#
  private static let pound = "#"
  private static let whitespaceSpacer = 2

  internal func processToken(_ token: TokenSyntax) {
    var kind = "\(token.tokenKind)"
    if let index = kind.firstIndex(of: Self.openParen) {
      kind = String(kind.prefix(upTo: index))
    }
    if kind.hasSuffix(Self.keyword) {
      kind = Self.keywordNormalized
    }

    // No longer needed for plain text output
    _ = token.sourceRange(converter: locationConverter)
    _ = token.presence == .present || showMissingTokens ? token.text : TokenVisitor.emptyString
  }

  internal func processTriviaPiece(_ piece: TriviaPiece) -> String {
    var trivia = TokenVisitor.emptyString
    switch piece {
    case .spaces(let count):
      trivia += String(repeating: " ", count: count)
    case .tabs(let count):
      trivia += String(repeating: "\t", count: count)
    case .verticalTabs, .formfeeds:
      break
    case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
      trivia += String(repeating: "\n", count: count)
    case .lineComment(let text):
      trivia += text
    case .blockComment(let text):
      trivia += text
    case .docLineComment(let text):
      trivia += text
    case .docBlockComment(let text):
      trivia += text
    case .unexpectedText(let text):
      trivia += text
    case .backslashes(let count):
      trivia += String(repeating: Self.backslash, count: count)
    case .pounds(let count):
      trivia += String(repeating: Self.pound, count: count)
    }
    return trivia
  }
}
