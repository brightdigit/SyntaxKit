//
//  If+Body.swift
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

extension If {
  /// Builds the body of the if expression.
  /// - Returns: The code block syntax for the body.
  public func buildBody() -> CodeBlockSyntax {
    CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: buildBodyStatements(from: body),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )
  }

  /// Builds the body statements from an array of code blocks.
  /// - Parameter blocks: The code blocks to convert to statements.
  /// - Returns: The code block item list syntax.
  public func buildBodyStatements(from blocks: [CodeBlock]) -> CodeBlockItemListSyntax {
    CodeBlockItemListSyntax(
      blocks.compactMap { block in
        createCodeBlockItem(from: block)?.with(\.trailingTrivia, .newline)
      }
    )
  }
}
