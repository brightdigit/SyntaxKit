//
//  TupleAssignment.swift
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
import SwiftSyntax

/// A tuple assignment statement for destructuring multiple values.
public struct TupleAssignment: CodeBlock {
  private let elements: [String]
  private let value: CodeBlock
  private var isAsync: Bool = false
  private var isThrowing: Bool = false
  private var isAsyncSet: Bool = false

  /// Creates a tuple destructuring declaration.
  /// - Parameters:
  ///   - elements: The names of the variables to destructure into.
  ///   - value: The expression to destructure.
  public init(_ elements: [String], equals value: CodeBlock) {
    self.elements = elements
    self.value = value
  }

  /// Marks this destructuring as async.
  /// - Returns: A copy of the destructuring marked as async.
  public func async() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }

  /// Marks this destructuring as throwing.
  /// - Returns: A copy of the destructuring marked as throwing.
  public func throwing() -> Self {
    var copy = self
    copy.isThrowing = true
    return copy
  }

  /// Marks this destructuring as concurrent async (async let set).
  /// - Returns: A copy of the destructuring marked as async set.
  public func asyncSet() -> Self {
    var copy = self
    copy.isAsyncSet = true
    return copy
  }

  /// The syntax representation of this tuple assignment.
  public var syntax: SyntaxProtocol {
    if isAsyncSet {
      return generateAsyncSetSyntax()
    }
    return generateRegularSyntax()
  }

  /// Generates the asyncSet tuple assignment syntax.
  private func generateAsyncSetSyntax() -> SyntaxProtocol {
    // Generate a single async let tuple destructuring assignment
    guard let tuple = value as? Tuple, elements.count == tuple.elements.count else {
      fatalError(
        "asyncSet requires a Tuple value with the same number of elements as the assignment.")
    }

    // Use helpers from AsyncSet
    let tuplePattern = AsyncSet.tuplePattern(elements: elements)
    let tupleExpr = AsyncSet.tupleExpr(tuple: tuple)
    let valueExpr = AsyncSet.valueExpr(tupleExpr: tupleExpr, isThrowing: isThrowing)

    // Build the async let declaration
    let asyncLet = CodeBlockItemSyntax(
      item: CodeBlockItemSyntax.Item.decl(
        DeclSyntax(
          VariableDeclSyntax(
            modifiers: DeclModifierListSyntax([
              DeclModifierSyntax(
                name: .keyword(.async, trailingTrivia: .space)
              )
            ]),
            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
            bindings: PatternBindingListSyntax([
              PatternBindingSyntax(
                pattern: tuplePattern,
                initializer: InitializerClauseSyntax(
                  equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                  value: valueExpr
                )
              )
            ])
          )
        )
      )
    )

    return CodeBlockSyntax(
      leftBrace: .leftBraceToken(),
      statements: CodeBlockItemListSyntax([asyncLet]),
      rightBrace: .rightBraceToken()
    )
  }

  /// Generates the regular tuple assignment syntax.
  private func generateRegularSyntax() -> SyntaxProtocol {
    // Build the tuple pattern
    let patternElements = TuplePatternElementListSyntax(
      elements.enumerated().map { index, element in
        TuplePatternElementSyntax(
          label: nil,
          colon: nil,
          pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(element))),
          trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
        )
      }
    )

    let tuplePattern = PatternSyntax(
      TuplePatternSyntax(
        leftParen: .leftParenToken(),
        elements: patternElements,
        rightParen: .rightParenToken()
      )
    )

    // Build the value expression
    let valueExpr = buildValueExpression()

    // Build the variable declaration
    return VariableDeclSyntax(
      bindingSpecifier: .keyword(.let, trailingTrivia: .space),
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: tuplePattern,
          initializer: InitializerClauseSyntax(
            equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
            value: valueExpr
          )
        )
      ])
    )
  }

  /// Builds the value expression based on async and throwing flags.
  private func buildValueExpression() -> ExprSyntax {
    let baseExpr =
      value.syntax.as(ExprSyntax.self)
      ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))

    if isThrowing {
      if isAsync {
        return ExprSyntax(
          TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: ExprSyntax(
              AwaitExprSyntax(
                awaitKeyword: .keyword(.await, trailingTrivia: .space),
                expression: baseExpr
              )
            )
          )
        )
      } else {
        return ExprSyntax(
          TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: baseExpr
          )
        )
      }
    } else {
      if isAsync {
        return ExprSyntax(
          AwaitExprSyntax(
            awaitKeyword: .keyword(.await, trailingTrivia: .space),
            expression: baseExpr
          )
        )
      } else {
        return baseExpr
      }
    }
  }
}
