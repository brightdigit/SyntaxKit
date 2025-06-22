//
//  PlusAssign.swift
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

/// A `+=` expression.
public struct PlusAssign: CodeBlock {
  private let target: String
  private let valueExpr: ExprSyntax

  /// Creates a `+=` expression with a literal value.
  public init(_ target: String, _ literal: Literal) {
    self.target = target
    guard let expr = literal.syntax.as(ExprSyntax.self) else {
      fatalError("Literal.syntax did not produce ExprSyntax")
    }
    self.valueExpr = expr
  }

  /// Creates a `+=` expression with an integer literal value.
  public init(_ target: String, _ value: Int) {
    self.init(target, .integer(value))
  }

  /// Creates a `+=` expression with a string literal value.
  public init(_ target: String, _ value: String) {
    self.init(target, .string(value))
  }

  /// Creates a `+=` expression with a boolean literal value.
  public init(_ target: String, _ value: Bool) {
    self.init(target, .boolean(value))
  }

  /// Creates a `+=` expression with a double literal value.
  public init(_ target: String, _ value: Double) {
    self.init(target, .float(value))
  }

  public var syntax: SyntaxProtocol {
    let left = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(target)))
    let assign = ExprSyntax(
      BinaryOperatorExprSyntax(
        operator: .binaryOperator(
          "+=",
          leadingTrivia: .space,
          trailingTrivia: .space
        )
      )
    )
    return SequenceExprSyntax(
      elements: ExprListSyntax([
        left,
        assign,
        valueExpr,
      ])
    )
  }
}
