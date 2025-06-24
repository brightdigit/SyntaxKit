//
//  Guard.swift
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

/// A `guard … else { … }` statement.
public struct Guard: CodeBlock {
  private let conditions: [CodeBlock]
  private let elseBody: [CodeBlock]

  /// Creates a `guard` statement.
  /// - Parameters:
  ///   - condition: A ``CodeBlockBuilder`` that provides the condition expression.
  ///   - else: A ``CodeBlockBuilder`` that provides the body when the condition is false.
  public init(
    @CodeBlockBuilderResult _ condition: () throws -> [CodeBlock],
    @CodeBlockBuilderResult else elseBody: () throws -> [CodeBlock]
  ) rethrows {
    let allConditions = try condition()
    if allConditions.isEmpty {
      // Use true as default condition when no conditions are provided
      self.conditions = [Literal.boolean(true)]
    } else {
      self.conditions = allConditions
    }
    self.elseBody = try elseBody()
  }

  /// Creates a `guard` statement with a string condition.
  /// - Parameters:
  ///   - condition: The condition as a string.
  ///   - else: A ``CodeBlockBuilder`` that provides the body when the condition is false.
  public init(
    _ condition: String,
    @CodeBlockBuilderResult else elseBody: () throws -> [CodeBlock]
  ) rethrows {
    self.conditions = [VariableExp(condition)]
    self.elseBody = try elseBody()
  }

  /// Convenience initializer that accepts a single condition ``CodeBlock``.
  public init(
    _ condition: CodeBlock,
    @CodeBlockBuilderResult else elseBody: () throws -> [CodeBlock]
  ) rethrows {
    try self.init({ condition }, else: elseBody)
  }

  public var syntax: SyntaxProtocol {
    // MARK: Build conditions list (mirror implementation from `If`)
    let condList = ConditionElementListSyntax(
      conditions.enumerated().map { index, block in
        let needsComma = index < conditions.count - 1
        func appendComma(_ element: ConditionElementSyntax) -> ConditionElementSyntax {
          needsComma ? element.with(\.trailingComma, .commaToken(trailingTrivia: .space)) : element
        }

        if let letCond = block as? Let {
          let element = ConditionElementSyntax(
            condition: .optionalBinding(
              OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(.let, trailingTrivia: .space),
                pattern: IdentifierPatternSyntax(identifier: .identifier(letCond.name)),
                initializer: InitializerClauseSyntax(
                  equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                  value: letCond.value.syntax.as(ExprSyntax.self)
                    ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
                )
              )
            )
          )
          return appendComma(element)
        } else {
          let element = ConditionElementSyntax(
            condition: .expression(
              ExprSyntax(
                fromProtocol: block.syntax.as(ExprSyntax.self)
                  ?? DeclReferenceExprSyntax(baseName: .identifier(""))
              )
            )
          )
          return appendComma(element)
        }
      }
    )

    // MARK: Build else body code block
    var elseItems: [CodeBlockItemSyntax] = elseBody.compactMap { block in
      if let decl = block.syntax.as(DeclSyntax.self) {
        return CodeBlockItemSyntax(item: .decl(decl)).with(\.trailingTrivia, .newline)
      } else if let expr = block.syntax.as(ExprSyntax.self) {
        return CodeBlockItemSyntax(item: .expr(expr)).with(\.trailingTrivia, .newline)
      } else if let stmt = block.syntax.as(StmtSyntax.self) {
        return CodeBlockItemSyntax(item: .stmt(stmt)).with(\.trailingTrivia, .newline)
      }
      return nil
    }

    // Automatically append a bare `return` if the user didn't provide a terminating statement.
    let containsTerminatingStatement = elseItems.contains { item in
      if case .stmt(let stmt) = item.item {
        return stmt.is(ReturnStmtSyntax.self) || stmt.is(ThrowStmtSyntax.self)
          || stmt.is(BreakStmtSyntax.self) || stmt.is(ContinueStmtSyntax.self)
      }
      return false
    }
    if !containsTerminatingStatement {
      let retStmt = ReturnStmtSyntax(returnKeyword: .keyword(.return))
      elseItems.append(
        CodeBlockItemSyntax(item: .stmt(StmtSyntax(retStmt))).with(\.trailingTrivia, .newline)
      )
    }

    let elseBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(elseItems),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    // Build and return GuardStmtSyntax wrapped in `StmtSyntax`
    return StmtSyntax(
      GuardStmtSyntax(
        guardKeyword: .keyword(.guard, trailingTrivia: .space),
        conditions: condList,
        elseKeyword: .keyword(.else, leadingTrivia: .space, trailingTrivia: .space),
        body: elseBlock
      )
    )
  }
}
