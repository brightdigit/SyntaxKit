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

public import SwiftSyntax

/// A Swift `while` loop.
public struct While: CodeBlock, Sendable {
  public enum Kind: Sendable {
    case `while`
    case repeatWhile
  }

  private let condition: any ExprCodeBlock
  private let body: [CodeBlock]
  private let kind: Kind

  /// Creates a `while` loop statement with an expression condition.
  /// - Parameters:
  ///   - condition: The condition expression that conforms to ExprCodeBlock.
  ///   - kind: The kind of loop (default is `.while`).
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    _ condition: any ExprCodeBlock,
    kind: Kind = .while,
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    self.condition = condition
    self.body = try then()
    self.kind = kind
  }

  /// Creates a `while` loop statement with a builder closure for the condition.
  /// - Parameters:
  ///   - condition: A `CodeBlockBuilder` that produces exactly one condition expression.
  ///   - kind: The kind of loop (default is `.while`).
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    kind: Kind = .while,
    @ExprCodeBlockBuilder _ condition: () throws -> any ExprCodeBlock,
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    self.condition = try condition()
    self.body = try then()
    self.kind = kind
  }

  /// Creates a `while` loop.
  /// - Parameters:
  ///   - condition: A ``CodeBlockBuilder`` that provides the condition expression.
  ///   - kind: The kind of loop (default is `.while`).
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  @available(
    *, deprecated,
    message: "Use While(kind:condition:) with ExprCodeBlockBuilder instead for better type safety"
  )
  public init(
    kind: Kind = .while,
    @CodeBlockBuilderResult _ condition: () throws -> [CodeBlock],
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    let conditionBlocks = try condition()
    let firstCondition = conditionBlocks.first as? any ExprCodeBlock ?? Literal.boolean(true)
    self.condition = firstCondition
    self.body = try then()
    self.kind = kind
  }

  /// Creates a `while` loop with a string condition.
  /// - Parameters:
  ///   - condition: The condition as a string.
  ///   - kind: The kind of loop (default is `.while`).
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  @available(
    *, deprecated,
    message: "Use While(VariableExp(condition), kind:then:) instead for better type safety"
  )
  public init(
    _ condition: String,
    kind: Kind = .while,
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    self.condition = VariableExp(condition)
    self.body = try then()
    self.kind = kind
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

    switch kind {
    case .repeatWhile:
      return StmtSyntax(
        RepeatWhileStmtSyntax(
          repeatKeyword: .keyword(.repeat, trailingTrivia: .space),
          body: bodyBlock,
          whileKeyword: .keyword(.while, trailingTrivia: .space),
          condition: conditionExpr
        )
      )
    case .while:
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
}
