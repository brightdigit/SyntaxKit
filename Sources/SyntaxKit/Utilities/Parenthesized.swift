//
//  Parenthesized.swift
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

/// A code block that wraps its content in parentheses.
public struct Parenthesized: CodeBlock, ExprCodeBlock {
  private let content: CodeBlock

  /// Creates a parenthesized code block.
  /// - Parameter content: The code block to wrap in parentheses.
  public init(@CodeBlockBuilderResult _ content: () -> [CodeBlock]) {
    let blocks = content()
    precondition(blocks.count == 1, "Parenthesized expects exactly one code block.")
    self.content = blocks[0]
  }

  public var exprSyntax: ExprSyntax {
    ExprSyntax(
      TupleExprSyntax(
        leftParen: .leftParenToken(),
        elements: LabeledExprListSyntax([
          LabeledExprSyntax(expression: content.expr)
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  public var syntax: SyntaxProtocol {
    exprSyntax
  }
}
