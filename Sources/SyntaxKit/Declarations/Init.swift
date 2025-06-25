//
//  Init.swift
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

/// A Swift initializer expression.
public struct Init: CodeBlock, ExprCodeBlock, LiteralValue, CodeBlockable, Sendable {
  private let type: String
  private let parameters: [ParameterExp]

  /// Creates an initializer expression with no parameters.
  /// - Parameter type: The type to initialize.
  public init(_ type: String) {
    self.type = type
    self.parameters = []
  }

  /// Creates an initializer expression.
  /// - Parameters:
  ///   - type: The type to initialize.
  ///   - params: A ``ParameterExpBuilderResult`` that provides the parameters for the initializer.
  public init(_ type: String, @ParameterExpBuilderResult _ params: () throws -> [ParameterExp])
    rethrows
  {
    self.type = type
    self.parameters = try params()
  }

  /// The code block representation of this initializer expression.
  public var codeBlock: CodeBlock {
    self
  }

  public var exprSyntax: ExprSyntax {
    var args = parameters
    var trailingClosure: ClosureExprSyntax?

    // If the last parameter is an unlabeled closure, use it as a trailing closure
    if let last = args.last, last.isUnlabeledClosure {
      // Flatten nested unlabeled closures
      if let closure = last.value as? Closure,
        closure.body.count == 1,
        let innerParam = closure.body.first as? ParameterExp,
        innerParam.isUnlabeledClosure,
        let innerClosure = innerParam.value as? Closure
      {
        trailingClosure = innerClosure.syntax.as(ClosureExprSyntax.self)
      } else if let closure = last.value as? Closure {
        trailingClosure = closure.syntax.as(ClosureExprSyntax.self)
      } else {
        trailingClosure = last.syntax.as(ClosureExprSyntax.self)
      }
      args.removeLast()
    }

    let labeledArgs = LabeledExprListSyntax(
      args.enumerated().compactMap { index, param in
        let element: LabeledExprSyntax
        if let labeled = param.syntax as? LabeledExprSyntax {
          element = labeled
        } else if let unlabeled = param.syntax.as(ExprSyntax.self) {
          element = LabeledExprSyntax(
            label: nil,
            colon: nil,
            expression: unlabeled
          )
        } else {
          return nil
        }
        if index < args.count - 1 {
          return element.with(
            \.trailingComma,
            .commaToken(trailingTrivia: .space)
          )
        }
        return element
      }
    )

    let requiresParanthesis = !labeledArgs.isEmpty || trailingClosure == nil
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: ExprSyntax(
          DeclReferenceExprSyntax(baseName: .identifier(type))
        ),
        leftParen: requiresParanthesis ? .leftParenToken() : nil,
        arguments: labeledArgs,
        rightParen: requiresParanthesis ? .rightParenToken() : nil,
        trailingClosure: trailingClosure
      )
    )
  }

  public var syntax: SyntaxProtocol {
    exprSyntax
  }

  /// Calls a method on this initializer.
  /// - Parameter methodName: The name of the method to call.
  /// - Returns: A code block that represents the method call.
  public func call(_ methodName: String) -> CodeBlock {
    FunctionCallExp(base: self, methodName: methodName)
  }

  /// Calls a method on this initializer with parameters.
  /// - Parameters:
  ///  - methodName: The name of the method to call.
  ///  - params: A ``ParameterExpBuilderResult`` that provides the parameters for the method call.
  /// - Returns: A code block that represents the method call.
  public func call(_ methodName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp])
    -> CodeBlock
  {
    FunctionCallExp(base: self, methodName: methodName, parameters: params())
  }

  // MARK: - LiteralValue Conformance

  public var typeName: String {
    type
  }

  public var literalString: String {
    "\(type)()"
  }
}
