//
//  VariableExp.swift
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

/// An expression that refers to a variable.
public struct VariableExp: CodeBlock, PatternConvertible {
  internal let name: String

  /// Creates a variable expression.
  /// - Parameter name: The name of the variable.
  public init(_ name: String) {
    self.name = name
  }

  /// Accesses a property on the variable.
  /// - Parameter propertyName: The name of the property to access.
  /// - Returns: A ``PropertyAccessExp`` that represents the property access.
  public func property(_ propertyName: String) -> PropertyAccessExp {
    PropertyAccessExp(base: self, propertyName: propertyName)
  }

  /// Calls a method on the variable.
  /// - Parameter methodName: The name of the method to call.
  /// - Returns: A ``FunctionCallExp`` that represents the method call.
  public func call(_ methodName: String) -> CodeBlock {
    FunctionCallExp(baseName: name, methodName: methodName)
  }

  /// Calls a method on the variable with parameters.
  /// - Parameters:
  ///  - methodName: The name of the method to call.
  ///  - params: A ``ParameterExpBuilder`` that provides the parameters for the method call.
  /// - Returns: A ``FunctionCallExp`` that represents the method call.
  public func call(_ methodName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp])
    -> CodeBlock
  {
    FunctionCallExp(baseName: name, methodName: methodName, parameters: params())
  }

  public var syntax: SyntaxProtocol {
    ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(name)))
  }

  public var patternSyntax: PatternSyntax {
    PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(name)))
  }
}

/// An expression that accesses a property on a base expression.
public struct PropertyAccessExp: CodeBlock {
  internal let base: CodeBlock
  internal let propertyName: String

  /// Creates a property access expression.
  /// - Parameters:
  ///  - base: The base expression.
  ///  - propertyName: The name of the property to access.
  public init(base: CodeBlock, propertyName: String) {
    self.base = base
    self.propertyName = propertyName
  }

  /// Convenience initializer for backward compatibility (baseName as String).
  public init(baseName: String, propertyName: String) {
    self.base = VariableExp(baseName)
    self.propertyName = propertyName
  }

  /// Accesses a property on the current property access expression (chaining).
  /// - Parameter propertyName: The name of the next property to access.
  /// - Returns: A new ``PropertyAccessExp`` representing the chained property access.
  public func property(_ propertyName: String) -> PropertyAccessExp {
    PropertyAccessExp(base: self, propertyName: propertyName)
  }

  /// Negates the property access expression.
  /// - Returns: A negated property access expression.
  public func not() -> CodeBlock {
    NegatedPropertyAccessExp(base: self)
  }

  public var syntax: SyntaxProtocol {
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
}

/// An expression that negates a property access.
public struct NegatedPropertyAccessExp: CodeBlock {
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

  public var syntax: SyntaxProtocol {
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
}

/// An expression that calls a function.
public struct FunctionCallExp: CodeBlock {
  internal let baseName: String
  internal let methodName: String
  internal let parameters: [ParameterExp]

  /// Creates a function call expression.
  /// - Parameters:
  ///   - baseName: The name of the base variable.
  ///   - methodName: The name of the method to call.
  public init(baseName: String, methodName: String) {
    self.baseName = baseName
    self.methodName = methodName
    self.parameters = []
  }

  /// Creates a function call expression with parameters.
  /// - Parameters:
  ///  - baseName: The name of the base variable.
  ///  - methodName: The name of the method to call.
  ///  - parameters: The parameters for the method call.
  public init(baseName: String, methodName: String, parameters: [ParameterExp]) {
    self.baseName = baseName
    self.methodName = methodName
    self.parameters = parameters
  }

  public var syntax: SyntaxProtocol {
    let base = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(baseName)))
    let method = TokenSyntax.identifier(methodName)
    let args = LabeledExprListSyntax(
      parameters.enumerated().map { index, param in
        let expr = param.syntax
        if let labeled = expr as? LabeledExprSyntax {
          var element = labeled
          if index < parameters.count - 1 {
            element = element.with(
              \.trailingComma,
              .commaToken(trailingTrivia: .space)
            )
          }
          return element
        } else if let unlabeled = expr as? ExprSyntax {
          return TupleExprElementSyntax(
            label: nil,
            colon: nil,
            expression: unlabeled,
            trailingComma: index < parameters.count - 1
              ? .commaToken(trailingTrivia: .space)
              : nil
          )
        } else {
          fatalError("ParameterExp.syntax must return LabeledExprSyntax or ExprSyntax")
        }
      }
    )
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: ExprSyntax(
          MemberAccessExprSyntax(
            base: base,
            dot: .periodToken(),
            name: method
          )
        ),
        leftParen: .leftParenToken(),
        arguments: args,
        rightParen: .rightParenToken()
      )
    )
  }
}
