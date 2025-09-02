//
//  SyntaxParser.swift
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
import SwiftOperators
import SwiftParser
import SwiftSyntax

package enum SyntaxParser {
  package static func parse(code: String, options: [String] = []) throws -> SyntaxResponse {
    let sourceFile = Parser.parse(source: code)

    let syntax: Syntax
    if options.contains("fold") {
      syntax = OperatorTable.standardOperators.foldAll(sourceFile, errorHandler: { _ in })
    } else {
      syntax = Syntax(sourceFile)
    }

    let visitor = TokenVisitor(
      locationConverter: SourceLocationConverter(fileName: "", tree: sourceFile),
      showMissingTokens: options.contains("showmissing")
    )
    _ = visitor.rewrite(syntax)

    let tree = visitor.tree
    let encoder = JSONEncoder()
    let data = try encoder.encode(tree)
    let json = String(decoding: data, as: UTF8.self)

    return SyntaxResponse(syntaxJSON: json)
  }
}
