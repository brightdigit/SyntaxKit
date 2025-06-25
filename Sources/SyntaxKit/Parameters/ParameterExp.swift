//
//  ParameterExp.swift
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

/// A parameter for a function call.
public struct ParameterExp: CodeBlock {
  internal let name: String
  internal let value: CodeBlock

  /// Creates a parameter for a function call.
  /// - Parameters:
  ///   - name: The name of the parameter.
  ///   - value: The value of the parameter.
  public init(name: String, value: CodeBlock) {
    self.name = name
    self.value = value
  }

  /// Creates a parameter for a function call with a string value.
  /// - Parameters:
  ///   - name: The name of the parameter.
  ///   - value: The string value of the parameter.
  @available(
    *, deprecated,
    message: "Use ParameterExp(name:value:) with Literal.string() or VariableExp() instead"
  )
  public init(name: String, value: String) {
    self.name = name
    self.value = VariableExp(value)
  }

  /// Convenience initializer for unlabeled parameter with a CodeBlock value.
  public init(unlabeled value: CodeBlock) {
    self.name = ""
    self.value = value
  }

  /// Convenience initializer for unlabeled parameter with a String value.
  @available(
    *, deprecated,
    message: "Use ParameterExp(unlabeled:) with Literal.string() or VariableExp() instead"
  )
  public init(unlabeled value: String) {
    self.name = ""
    self.value = VariableExp(value)
  }

  public var syntax: SyntaxProtocol {
    if name.isEmpty {
      if let exprBlock = value as? ExprCodeBlock {
        return exprBlock.exprSyntax
      } else {
        return value.syntax.as(ExprSyntax.self)
          ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
      }
    } else {
      let expression: ExprSyntax
      if let exprBlock = value as? ExprCodeBlock {
        expression = exprBlock.exprSyntax
      } else {
        expression =
          value.syntax.as(ExprSyntax.self)
          ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
      }
      return LabeledExprSyntax(
        label: .identifier(name),
        colon: .colonToken(trailingTrivia: .init()),
        expression: expression
      )
    }
  }

  internal var isUnlabeledClosure: Bool {
    name.isEmpty && value is Closure
  }
}
