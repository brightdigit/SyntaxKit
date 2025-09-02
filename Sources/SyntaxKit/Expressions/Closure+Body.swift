//
//  Closure+Body.swift
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

public import SwiftSyntax

extension Closure {
  /// Builds the body block for the closure.
  internal func buildBodyBlock() -> CodeBlockItemListSyntax {
    CodeBlockItemListSyntax(
      body.compactMap(buildBodyItem)
    )
  }

  /// Builds a body item from a code block.
  private func buildBodyItem(from codeBlock: CodeBlock) -> CodeBlockItemSyntax? {
    if let decl = codeBlock.syntax.as(DeclSyntax.self) {
      return CodeBlockItemSyntax(item: .decl(decl)).with(\.trailingTrivia, .newline)
    } else if let paramExp = codeBlock as? ParameterExp {
      return buildParameterExpressionItem(paramExp)
    } else if let exprBlock = codeBlock as? ExprCodeBlock {
      return CodeBlockItemSyntax(item: .expr(exprBlock.exprSyntax)).with(
        \.trailingTrivia, .newline
      )
    } else if let expr = codeBlock.syntax.as(ExprSyntax.self) {
      return CodeBlockItemSyntax(item: .expr(expr)).with(
        \.trailingTrivia, .newline
      )
    } else if let stmt = codeBlock.syntax.as(StmtSyntax.self) {
      return CodeBlockItemSyntax(item: .stmt(stmt)).with(\.trailingTrivia, .newline)
    }
    return nil
  }

  /// Builds a parameter expression item.
  private func buildParameterExpressionItem(_ paramExp: ParameterExp) -> CodeBlockItemSyntax? {
    if let exprBlock = paramExp.value as? ExprCodeBlock {
      return CodeBlockItemSyntax(item: .expr(exprBlock.exprSyntax)).with(
        \.trailingTrivia, .newline
      )
    } else if let expr = paramExp.value.syntax.as(ExprSyntax.self) {
      return CodeBlockItemSyntax(item: .expr(expr)).with(
        \.trailingTrivia, .newline
      )
    } else if let paramExpr = paramExp.syntax.as(ExprSyntax.self) {
      return CodeBlockItemSyntax(item: .expr(paramExpr)).with(
        \.trailingTrivia, .newline
      )
    }
    return nil
  }
}
