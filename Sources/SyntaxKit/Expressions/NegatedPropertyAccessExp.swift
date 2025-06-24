//
//  NegatedPropertyAccessExp.swift
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

/// An expression that negates a property access.
public struct NegatedPropertyAccessExp: CodeBlock, ExprCodeBlock {
  internal let base: CodeBlock

  /// Creates a negated property access expression.
  /// - Parameter base: The base property access expression.
  public init(base: CodeBlock) {
    self.base = base
  }

  /// Backward compatibility initializer for (baseName, propertyName).
  public init(baseName: String, propertyName: String) {
    self.base = PropertyAccessExp(baseName: baseName, propertyName: propertyName)
  }

  public var exprSyntax: ExprSyntax {
    let memberAccess =
      base.syntax.as(ExprSyntax.self)
      ?? ExprSyntax(
        DeclReferenceExprSyntax(baseName: .identifier(""))
      )
    return ExprSyntax(
      PrefixOperatorExprSyntax(
        operator: .prefixOperator(
          "!",
          leadingTrivia: [],
          trailingTrivia: []
        ),
        expression: memberAccess
      )
    )
  }

  public var syntax: SyntaxProtocol {
    exprSyntax
  }
}
