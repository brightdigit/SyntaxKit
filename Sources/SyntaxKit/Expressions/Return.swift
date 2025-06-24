//
//  Return.swift
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

/// A `return` statement.
public struct Return: CodeBlock {
  private let exprs: [CodeBlock]

  /// Creates a `return` statement.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the expression to return.
  public init(@CodeBlockBuilderResult _ content: () throws -> [CodeBlock]) rethrows {
    self.exprs = try content()
  }
  public var syntax: SyntaxProtocol {
    if let expr = exprs.first {
      if let varExp = expr as? VariableExp {
        return ReturnStmtSyntax(
          returnKeyword: .keyword(.return, trailingTrivia: .space),
          expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(varExp.name)))
        )
      }

      // Try to get ExprSyntax from the expression
      let exprSyntax: ExprSyntax
      if let exprCodeBlock = expr as? ExprCodeBlock {
        exprSyntax = exprCodeBlock.exprSyntax
      } else if let syntax = expr.syntax.as(ExprSyntax.self) {
        exprSyntax = syntax
      } else {
        // fallback: no valid expression
        #warning(
          "TODO: Review fallback for no valid expression - consider if this should be an error instead"
        )
        return ReturnStmtSyntax(
          returnKeyword: .keyword(.return, trailingTrivia: .space)
        )
      }

      return ReturnStmtSyntax(
        returnKeyword: .keyword(.return, trailingTrivia: .space),
        expression: exprSyntax
      )
    } else {
      // Bare return
      return ReturnStmtSyntax(
        returnKeyword: .keyword(.return, trailingTrivia: .space)
      )
    }
  }
}
