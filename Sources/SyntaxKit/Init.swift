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

/// An initializer expression.
public struct Init: CodeBlock, ExprCodeBlock, LiteralValue {
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
  ///   - params: A ``ParameterExpBuilder`` that provides the parameters for the initializer.
  public init(_ type: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp]) {
    self.type = type
    self.parameters = params()
  }

  public var exprSyntax: ExprSyntax {
    let args = LabeledExprListSyntax(
      parameters.enumerated().compactMap { index, param in
        guard let element = param.syntax as? LabeledExprSyntax else {
          return nil
        }
        if index < parameters.count - 1 {
          return element.with(\.trailingComma, .commaToken(trailingTrivia: .space))
        }
        return element
      })
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(type))),
        leftParen: .leftParenToken(),
        arguments: args,
        rightParen: .rightParenToken()
      ))
  }

  public var syntax: SyntaxProtocol {
    exprSyntax
  }

  // MARK: - LiteralValue Conformance

  public var typeName: String {
    type
  }

  public var literalString: String {
    "\(type)()"
  }
}
