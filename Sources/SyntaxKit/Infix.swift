//
//  Infix.swift
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

/// A generic binary (infix) operator expression, e.g. `a + b`.
public struct Infix: CodeBlock {
  private let operation: String
  private let operands: [CodeBlock]

  /// Creates an infix operator expression.
  /// - Parameters:
  ///   - operation: The operator symbol as it should appear in source (e.g. "+", "-", "&&").
  ///   - content: A ``CodeBlockBuilder`` that supplies the two operand expressions.
  ///
  /// Exactly two operands must be supplied – a left-hand side and a right-hand side.
  public init(_ operation: String, @CodeBlockBuilderResult _ content: () -> [CodeBlock]) {
    self.operation = operation
    self.operands = content()
  }

  public var syntax: SyntaxProtocol {
    guard operands.count == 2 else {
      fatalError("Infix expects exactly two operands, got \(operands.count).")
    }

    let left = operands[0].expr
    let right = operands[1].expr

    let operatorExpr = ExprSyntax(
      BinaryOperatorExprSyntax(
        operator: .binaryOperator(operation, leadingTrivia: .space, trailingTrivia: .space)
      )
    )

    return SequenceExprSyntax(
      elements: ExprListSyntax([
        left,
        operatorExpr,
        right,
      ])
    )
  }
}

// MARK: - Comparison Operators

extension Infix {
  /// Comparison operators that can be used in infix expressions.
  public enum ComparisonOperator: String, CaseIterable {
    case greaterThan = ">"
    case lessThan = "<"
    case equal = "=="
    case notEqual = "!="

    /// The string representation of the operator.
    public var symbol: String {
      rawValue
    }
  }

  /// Creates an infix expression with a comparison operator.
  /// - Parameters:
  ///   - operator: The comparison operator to use.
  ///   - lhs: The left-hand side expression.
  ///   - rhs: The right-hand side expression.
  public init(_ operator: ComparisonOperator, lhs: CodeBlock, rhs: CodeBlock) {
    self.operation = `operator`.symbol
    self.operands = [lhs, rhs]
  }
}
