//
//  ConditionalOp.swift
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

/// A Swift ternary conditional operator expression (`condition ? then : else`).
public struct ConditionalOp: CodeBlock {
  private let condition: any CodeBlock
  private let thenExpression: any CodeBlock
  private let elseExpression: any CodeBlock

  public var syntax: any SyntaxProtocol {
    let conditionExpr = ExprSyntax(
      fromProtocol: condition.syntax.as(ExprSyntax.self)
        ?? DeclReferenceExprSyntax(baseName: .identifier(""))
    )

    // Handle EnumCase specially - use asExpressionSyntax for expressions
    let thenExpr: ExprSyntax
    if let enumCase = thenExpression as? EnumCase {
      thenExpr = enumCase.asExpressionSyntax
    } else {
      thenExpr = ExprSyntax(
        fromProtocol: thenExpression.syntax.as(ExprSyntax.self)
          ?? DeclReferenceExprSyntax(baseName: .identifier(""))
      )
    }

    let elseExpr: ExprSyntax
    if let enumCase = elseExpression as? EnumCase {
      elseExpr = enumCase.asExpressionSyntax
    } else {
      elseExpr = ExprSyntax(
        fromProtocol: elseExpression.syntax.as(ExprSyntax.self)
          ?? DeclReferenceExprSyntax(baseName: .identifier(""))
      )
    }

    return TernaryExprSyntax(
      condition: conditionExpr,
      questionMark: .infixQuestionMarkToken(leadingTrivia: .space, trailingTrivia: .space),
      thenExpression: thenExpr,
      colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
      elseExpression: elseExpr
    )
  }

  /// Creates a ternary conditional operator expression.
  /// - Parameters:
  ///   - condition: The condition expression.
  ///   - thenExpression: The expression to evaluate if the condition is true.
  ///   - elseExpression: The expression to evaluate if the condition is false.
  public init(
    if condition: any CodeBlock,
    then thenExpression: any CodeBlock,
    else elseExpression: any CodeBlock
  ) {
    self.condition = condition
    self.thenExpression = thenExpression
    self.elseExpression = elseExpression
  }
}
