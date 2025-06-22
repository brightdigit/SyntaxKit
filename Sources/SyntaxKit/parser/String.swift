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

extension String {
  internal func escapeHTML() -> String {
    var string = self
    let specialCharacters = [
      ("&", "&amp;"),
      ("<", "&lt;"),
      (">", "&gt;"),
      ("\"", "&quot;"),
      ("'", "&apos;"),
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
      .replacingOccurrences(of: " ", with: "&nbsp;")
      .replacingOccurrences(of: "\n", with: "<br/>")
  }

  internal func replaceInvisiblesWithSymbols() -> String {
    self
      .replacingOccurrences(of: " ", with: "␣")
      .replacingOccurrences(of: "\n", with: "↲")
  }

  internal func replaceHTMLWhitespacesWithSymbols() -> String {
    self
      .replacingOccurrences(of: "&nbsp;", with: "<span class='whitespace'>␣</span>")
      .replacingOccurrences(of: "<br/>", with: "<span class='newline'>↲</span><br/>")
  }
}
