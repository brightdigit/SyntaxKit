//
//  If.swift
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

/// An `if` statement.
public struct If: CodeBlock {
  internal let conditions: [CodeBlock]
  internal let body: [CodeBlock]
  internal let elseBody: [CodeBlock]?

  /// Creates an `if` statement with optional `else`.
  /// - Parameters:
  ///   - condition: A single `CodeBlock` produced by the builder that describes the `if` condition.
  ///   - then: Builder that produces the body for the `if` branch.
  ///   - elseBody: Builder that produces the body for the `else` branch. The body may contain
  ///               nested `If` instances (representing `else if`) and/or a ``Then`` block for the
  ///               final `else` statements.
  public init(
    @CodeBlockBuilderResult _ condition: () -> [CodeBlock],
    @CodeBlockBuilderResult then: () -> [CodeBlock],
    @CodeBlockBuilderResult else elseBody: () -> [CodeBlock] = { [] }
  ) {
    let allConditions = condition()
    guard !allConditions.isEmpty else {
      fatalError("If requires at least one condition CodeBlock")
    }
    self.conditions = allConditions
    self.body = then()
    let generatedElse = elseBody()
    self.elseBody = generatedElse.isEmpty ? nil : generatedElse
  }

  /// Convenience initializer that keeps the previous API: pass the condition directly.
  public init(
    _ condition: CodeBlock,
    @CodeBlockBuilderResult then: () -> [CodeBlock],
    @CodeBlockBuilderResult else elseBody: () -> [CodeBlock] = { [] }
  ) {
    self.init({ condition }, then: then, else: elseBody)
  }

  public var syntax: SyntaxProtocol {
    // Build list of ConditionElements from all provided conditions
    let condList = buildConditions()
    let bodyBlock = buildBody()
    let elseBlock = buildElseBody()

    return ExprSyntax(
      IfExprSyntax(
        ifKeyword: .keyword(.if, trailingTrivia: .space),
        conditions: condList,
        body: bodyBlock,
        elseKeyword: elseBlock != nil
          ? .keyword(.else, leadingTrivia: .space, trailingTrivia: .space) : nil,
        elseBody: elseBlock
      )
    )
  }
}
