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

public import SwiftSyntax

/// A generic binary (infix) operator expression, e.g. `a + b`.
public struct Infix: CodeBlock, ExprCodeBlock {
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

  public enum InfixError: Error, CustomStringConvertible {
    case wrongOperandCount(expected: Int, got: Int)
    case nonExprCodeBlockOperand

    public var description: String {
      switch self {
      case let .wrongOperandCount(expected, got):
        return "Infix expects exactly \(expected) operands, got \(got)."
      case .nonExprCodeBlockOperand:
        return "Infix operands must conform to ExprCodeBlock protocol"
      }
    }
  }

  private let operation: String
  private let leftOperand: any ExprCodeBlock
  private let rightOperand: any ExprCodeBlock

  public var exprSyntax: ExprSyntax {
    let left = leftOperand.exprSyntax
    let right = rightOperand.exprSyntax

    let operatorExpr = ExprSyntax(
      BinaryOperatorExprSyntax(
        operator: .binaryOperator(operation, leadingTrivia: .space, trailingTrivia: .space)
      )
    )

    return ExprSyntax(
      SequenceExprSyntax(
        elements: ExprListSyntax([
          left,
          operatorExpr,
          right,
        ])
      )
    )
  }

  public var syntax: any SyntaxProtocol {
    exprSyntax
  }

  /// Creates an infix expression with a comparison operator.
  /// - Parameters:
  ///   - operator: The comparison operator to use.
  ///   - lhs: The left-hand side expression.
  ///   - rhs: The right-hand side expression.
  public init(_ operator: ComparisonOperator, lhs: any ExprCodeBlock, rhs: any ExprCodeBlock) {
    self.operation = `operator`.symbol
    self.leftOperand = lhs
    self.rightOperand = rhs
  }

  /// Creates an infix operator expression.
  /// - Parameters:
  ///   - operation: The operator symbol as it should appear in source (e.g. "+", "-", "&&").
  ///   - lhs: The left-hand side expression that conforms to ExprCodeBlock.
  ///   - rhs: The right-hand side expression that conforms to ExprCodeBlock.
  public init(_ operation: String, lhs: any ExprCodeBlock, rhs: any ExprCodeBlock) {
    self.operation = operation
    self.leftOperand = lhs
    self.rightOperand = rhs
  }

  /// Creates an infix operator expression with a builder closure.
  /// - Parameters:
  ///   - operation: The operator symbol as it should appear in source (e.g. "+", "-", "&&").
  ///   - content: A ``CodeBlockBuilder`` that supplies exactly two operand expressions.
  ///
  /// Exactly two operands must be supplied – a left-hand side and a right-hand side.
  /// Each operand must conform to ExprCodeBlock.
  @available(*, deprecated, message: "Use separate lhs and rhs parameters for compile-time safety")
  public init(_ operation: String, @CodeBlockBuilderResult _ content: () throws -> [any CodeBlock])
    throws
  {
    self.operation = operation
    let operands = try content()

    guard operands.count == 2 else {
      throw InfixError.wrongOperandCount(expected: 2, got: operands.count)
    }
    guard let lhs = operands[0] as? any ExprCodeBlock,
      let rhs = operands[1] as? any ExprCodeBlock
    else {
      throw InfixError.nonExprCodeBlockOperand
    }
    self.leftOperand = lhs
    self.rightOperand = rhs
  }
}
