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

public import SwiftSyntax

/// An expression that refers to a variable.
public struct VariableExp: CodeBlock, PatternConvertible, ExprCodeBlock {
  internal let name: String

  /// Creates a variable expression.
  /// - Parameter name: The name of the variable.
  public init(_ name: String) {
    self.name = name
  }

  /// Accesses a property on the variable.
  /// - Parameter propertyName: The name of the property to access.
  /// - Returns: A property accessible code block that represents the property access.
  public func property(_ propertyName: String) -> PropertyAccessible {
    PropertyAccessExp(base: self, propertyName: propertyName)
  }

  /// Negates property access on the variable.
  /// - Parameter propertyName: The name of the property to access.
  /// - Returns: A code block that represents the negated property access.
  public func negatedProperty(_ propertyName: String) -> CodeBlock {
    NegatedPropertyAccessExp(base: PropertyAccessExp(base: self, propertyName: propertyName))
  }

  /// Calls a method on the variable.
  /// - Parameter methodName: The name of the method to call.
  /// - Returns: A code block that represents the method call.
  public func call(_ methodName: String) -> CodeBlock {
    FunctionCallExp(baseName: name, methodName: methodName)
  }

  /// Calls a method on the variable with parameters.
  /// - Parameters:
  ///  - methodName: The name of the method to call.
  ///  - params: A ``ParameterExpBuilderResult`` that provides the parameters for the method call.
  /// - Returns: A code block that represents the method call.
  public func call(_ methodName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp])
    -> CodeBlock
  {
    FunctionCallExp(baseName: name, methodName: methodName, parameters: params())
  }

  /// Performs optional chaining on the variable.
  /// - Returns: A code block that represents the optional chaining.
  public func optionalChaining() -> CodeBlock {
    OptionalChainingExp(base: self)
  }

  /// Creates an optional chaining expression for this variable.
  /// - Returns: An optional chaining expression.
  public func optional() -> CodeBlock {
    OptionalChainingExp(base: self)
  }

  /// Creates a reference to the variable.
  /// - Parameter referenceType: The type of reference to create.
  /// - Returns: A code block that represents the reference.
  public func reference(_ referenceType: CaptureReferenceType) -> CodeBlock {
    ReferenceExp(base: self, referenceType: referenceType)
  }

  public var syntax: SyntaxProtocol {
    ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(name)))
  }

  public var exprSyntax: ExprSyntax {
    ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(name)))
  }

  public var patternSyntax: PatternSyntax {
    PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(name)))
  }
}
