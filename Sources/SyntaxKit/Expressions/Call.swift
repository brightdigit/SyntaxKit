//
//  Call.swift
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

/// An expression that calls a global function.
public struct Call: CodeBlock {
  private let functionName: String
  private let parameters: [ParameterExp]
  private var isThrowing: Bool = false
  private var isAsync: Bool = false

  /// Creates a global function call expression.
  /// - Parameter functionName: The name of the function to call.
  public init(_ functionName: String) {
    self.functionName = functionName
    self.parameters = []
  }

  /// Creates a global function call expression with parameters.
  /// - Parameters:
  ///   - functionName: The name of the function to call.
  ///   - params: A ``ParameterExpBuilder`` that provides the parameters for the function call.
  public init(_ functionName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp]) {
    self.functionName = functionName
    self.parameters = params()
  }

  /// Marks this function call as throwing.
  /// - Returns: A copy of the call marked as throwing.
  public func throwing() -> Self {
    var copy = self
    copy.isThrowing = true
    return copy
  }

  /// Marks this function call as async.
  /// - Returns: A copy of the call marked as async.
  public func async() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }

  public var syntax: SyntaxProtocol {
    let function = TokenSyntax.identifier(functionName)
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
          return LabeledExprSyntax(
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

    let functionCall = FunctionCallExprSyntax(
      calledExpression: ExprSyntax(
        DeclReferenceExprSyntax(baseName: function)
      ),
      leftParen: .leftParenToken(),
      arguments: args,
      rightParen: .rightParenToken()
    )

    if isThrowing {
      return ExprSyntax(
        TryExprSyntax(
          tryKeyword: .keyword(.try, trailingTrivia: .space),
          expression: functionCall
        )
      )
    } else if isAsync {
      return ExprSyntax(
        AwaitExprSyntax(
          awaitKeyword: .keyword(.await, trailingTrivia: .space),
          expression: functionCall
        )
      )
    } else {
      return ExprSyntax(functionCall)
    }
  }
}
