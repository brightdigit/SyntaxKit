//
//  String.swift
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

extension String {
  // HTML Entities
  private static let ampersand = "&"
  private static let ampersandEntity = "&amp;"
  private static let lessThan = "<"
  private static let lessThanEntity = "&lt;"
  private static let greaterThan = ">"
  private static let greaterThanEntity = "&gt;"
  private static let doubleQuote = "\""
  private static let doubleQuoteEntity = "&quot;"
  private static let singleQuote = "'"
  private static let singleQuoteEntity = "&apos;"

  // HTML Tags
  private static let nonBreakingSpace = "&nbsp;"
  private static let lineBreak = "<br/>"
  private static let lineBreakShort = "<br>"

  // Symbols
  private static let space = " "
  private static let newline = "\n"
  private static let spaceSymbol = "␣"
  private static let newlineSymbol = "↲"

  // CSS Classes
  private static let whitespace = "whitespace"
  private static let newlineClass = "newline"

  internal func escapeHTML() -> String {
    var string = self
    let specialCharacters = [
      (Self.ampersand, Self.ampersandEntity),
      (Self.lessThan, Self.lessThanEntity),
      (Self.greaterThan, Self.greaterThanEntity),
      (Self.doubleQuote, Self.doubleQuoteEntity),
      (Self.singleQuote, Self.singleQuoteEntity),
    ]
    for (unescaped, escaped) in specialCharacters {
      string = string.replacingOccurrences(
        of: unescaped,
        with: escaped,
        options: .literal,
        range: nil
      )
    }
    return string
  }

  internal func replaceInvisiblesWithHTML() -> String {
    self
      .replacingOccurrences(of: Self.space, with: Self.nonBreakingSpace)
      .replacingOccurrences(of: Self.newline, with: Self.lineBreak)
  }

  internal func replaceInvisiblesWithSymbols() -> String {
    self
      .replacingOccurrences(of: Self.space, with: Self.spaceSymbol)
      .replacingOccurrences(of: Self.newline, with: Self.newlineSymbol)
  }

  internal func replaceHTMLWhitespacesWithSymbols() -> String {
    self
      .replacingOccurrences(
        of: Self.nonBreakingSpace,
        with:
          "<span class='\(Self.whitespace)'>\(Self.spaceSymbol)</span>"
      )
      .replacingOccurrences(
        of: Self.lineBreak,
        with:
          "<span class='\(Self.newlineClass)'>\(Self.newlineSymbol)</span>\(Self.lineBreak)"
      )
  }

  internal func replaceHTMLWhitespacesToSymbols() -> String {
    self
      .replacingOccurrences(
        of: Self.nonBreakingSpace,
        with:
          "<span class='\(Self.whitespace)'>\(Self.spaceSymbol)</span>"
      )
      .replacingOccurrences(
        of: Self.lineBreakShort,
        with:
          "<span class='\(Self.newlineClass)'>\(Self.newlineSymbol)</span>")
  }
}
