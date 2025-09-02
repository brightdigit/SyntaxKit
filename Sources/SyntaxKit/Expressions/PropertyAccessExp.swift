//
//  PropertyAccessExp.swift
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

/// An expression that accesses a property.
internal struct PropertyAccessExp: CodeBlock, ExprCodeBlock, PropertyAccessible {
  internal let base: any CodeBlock
  internal let propertyName: String

  /// Creates a property access expression.
  /// - Parameters:
  ///  - base: The base expression.
  ///  - propertyName: The name of the property to access.
  internal init(base: any CodeBlock, propertyName: String) {
    self.base = base
    self.propertyName = propertyName
  }

  /// Convenience initializer for backward compatibility (baseName as String).
  internal init(baseName: String, propertyName: String) {
    self.base = VariableExp(baseName)
    self.propertyName = propertyName
  }

  /// Accesses a property on the current property access expression (chaining).
  /// - Parameter propertyName: The name of the next property to access.
  /// - Returns: A property accessible code block representing the chained property access.
  internal func property(_ propertyName: String) -> any PropertyAccessible {
    PropertyAccessExp(base: self, propertyName: propertyName)
  }

  /// Negates the property access expression.
  /// - Returns: A negated property access expression.
  internal func not() -> any CodeBlock {
    NegatedPropertyAccessExp(base: self)
  }

  internal var exprSyntax: ExprSyntax {
    let baseSyntax =
      base.syntax.as(ExprSyntax.self)
      ?? ExprSyntax(
        DeclReferenceExprSyntax(baseName: .identifier(""))
      )
    let property = TokenSyntax.identifier(propertyName)
    return ExprSyntax(
      MemberAccessExprSyntax(
        base: baseSyntax,
        dot: .periodToken(),
        name: property
      )
    )
  }

  internal var syntax: any SyntaxProtocol {
    exprSyntax
  }
}
