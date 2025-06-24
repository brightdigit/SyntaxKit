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
  private let base: CodeBlock?

  /// Creates a function call expression on a variable name.
  public init(baseName: String, methodName: String) {
    self.baseName = baseName
    self.methodName = methodName
    self.parameters = []
    self.base = nil
  }

  /// Creates a function call expression with parameters on a variable name.
  public init(baseName: String, methodName: String, parameters: [ParameterExp]) {
    self.baseName = baseName
    self.methodName = methodName
    self.parameters = parameters
    self.base = nil
  }

  /// Creates a function call expression on an arbitrary base expression.
  public init(base: CodeBlock, methodName: String, parameters: [ParameterExp] = []) {
    self.baseName = ""
    self.methodName = methodName
    self.parameters = parameters
    self.base = base
  }

  public var syntax: SyntaxProtocol {
    let baseExpr: ExprSyntax
    if let base = base {
      if let exprSyntax = base.syntax.as(ExprSyntax.self) {
        // If the base is a ConditionalOp, wrap it in parentheses for proper precedence
        if base is ConditionalOp {
          baseExpr = ExprSyntax(
            TupleExprSyntax(
              leftParen: .leftParenToken(),
              elements: LabeledExprListSyntax([
                LabeledExprSyntax(expression: exprSyntax)
              ]),
              rightParen: .rightParenToken()
            )
          )
        } else {
          baseExpr = exprSyntax
        }
      } else {
        baseExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
      }
    } else {
      baseExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(baseName)))
    }

    // Trailing closure logic
    var args = parameters
    var trailingClosure: ClosureExprSyntax?
    if let last = args.last, last.isUnlabeledClosure {
      trailingClosure = last.syntax.as(ClosureExprSyntax.self)
      args.removeLast()
    }

    let labeledArgs = LabeledExprListSyntax(
      args.enumerated().compactMap { index, param in
        let expr = param.syntax
        if let labeled = expr as? LabeledExprSyntax {
          var element = labeled
          if index < args.count - 1 {
            element = element.with(
              \.trailingComma,
              .commaToken(trailingTrivia: .space)
            )
          }
          return element
        } else if let unlabeled = expr as? ExprSyntax {
          // ParameterExp.syntax is guaranteed to return either LabeledExprSyntax or ExprSyntax

          return LabeledExprSyntax(
            label: nil,
            colon: nil,
            expression: unlabeled,
            trailingComma: index < args.count - 1
              ? .commaToken(trailingTrivia: .space)
              : nil
          )
        } else {
          return nil
        }
      }
    )

    var functionCall = FunctionCallExprSyntax(
      calledExpression: ExprSyntax(
        MemberAccessExprSyntax(
          base: baseExpr,
          dot: .periodToken(),
          name: .identifier(methodName)
        )
      ),
      leftParen: .leftParenToken(),
      arguments: labeledArgs,
      rightParen: .rightParenToken(),
      trailingClosure: trailingClosure
    )

    return ExprSyntax(functionCall)
  }
}
