//
//  While.swift
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

/// A `while` loop statement.
public struct While: CodeBlock {
  private let condition: any ExprCodeBlock
  private let body: [CodeBlock]

  /// Creates a `while` loop statement with an expression condition.
  /// - Parameters:
  ///   - condition: The condition expression that conforms to ExprCodeBlock.
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    _ condition: any ExprCodeBlock,
    @CodeBlockBuilderResult then: () -> [CodeBlock]
  ) {
    self.condition = condition
    self.body = then()
  }

  /// Creates a `while` loop statement with a builder closure for the condition.
  /// - Parameters:
  ///   - condition: A `CodeBlockBuilder` that produces exactly one condition expression.
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    @ExprCodeBlockBuilder _ condition: () -> any ExprCodeBlock,
    @CodeBlockBuilderResult then: () -> [CodeBlock]
  ) {
    self.condition = condition()
    self.body = then()
  }

  /// Legacy initializer for backward compatibility.
  /// - Parameters:
  ///   - condition: A `CodeBlockBuilder` that produces the condition expression.
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  @available(*, deprecated, message: "Use ExprCodeBlockBuilder instead for compile-time safety")
  public init(
    @CodeBlockBuilderResult _ condition: () -> [CodeBlock],
    @CodeBlockBuilderResult then: () -> [CodeBlock]
  ) {
    let conditions = condition()
    guard conditions.count == 1 else {
      fatalError("While requires exactly one condition CodeBlock")
    }
    guard let exprCondition = conditions[0] as? any ExprCodeBlock else {
      fatalError("While condition must conform to ExprCodeBlock protocol")
    }
    self.condition = exprCondition
    self.body = then()
  }

  public var syntax: SyntaxProtocol {
    let conditionExpr = condition.exprSyntax

    let bodyBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap {
          var item: CodeBlockItemSyntax?
          if let decl = $0.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = $0.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = $0.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return item?.with(\.trailingTrivia, .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    return StmtSyntax(
      WhileStmtSyntax(
        whileKeyword: .keyword(.while, trailingTrivia: .space),
        conditions: ConditionElementListSyntax(
          [
            ConditionElementSyntax(
              condition: .expression(conditionExpr)
            )
          ]
        ),
        body: bodyBlock
      )
    )
  }
}
