//
//  FunctionCallExp.swift
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
