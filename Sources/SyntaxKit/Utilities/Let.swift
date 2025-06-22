//
//  Let.swift
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

/// A Swift `let` declaration for use in an `if` statement.
public struct Let: CodeBlock {
  internal let name: String
  internal let value: CodeBlock

  /// Creates a `let` declaration for an `if` statement.
  /// - Parameters:
  ///   - name: The name of the constant.
  ///   - value: The value to assign to the constant.
  public init(_ name: String, _ value: CodeBlock) {
    self.name = name
    self.value = value
  }

  /// Creates a `let` declaration for an `if` statement with a string value.
  /// - Parameters:
  ///   - name: The name of the constant.
  ///   - value: The string value to assign to the constant.
  public init(_ name: String, _ value: String) {
    self.name = name
    self.value = VariableExp(value)
  }

  public var syntax: SyntaxProtocol {
    CodeBlockItemSyntax(
      item: .decl(
        DeclSyntax(
          VariableDeclSyntax(
            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
            bindings: PatternBindingListSyntax([
              PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
                initializer: InitializerClauseSyntax(
                  equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                  value: value.syntax.as(ExprSyntax.self)
                    ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
                )
              )
            ])
          )
        )
      )
    )
  }
}
