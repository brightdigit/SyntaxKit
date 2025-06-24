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

  /// Creates a reference to this variable.
  /// - Parameter referenceType: The type of reference (e.g., "weak", "unowned").
  /// - Returns: A reference expression.
  public func reference(_ referenceType: String) -> CodeBlock {
    ReferenceExp(base: self, referenceType: referenceType)
  }

  /// Creates an optional chaining expression for this variable.
  /// - Returns: An optional chaining expression.
  public func optional() -> CodeBlock {
    OptionalChainingExp(base: self)
  }

  public var syntax: SyntaxProtocol {
    ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(name)))
  }

  public var patternSyntax: PatternSyntax {
    PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(name)))
  }
}
