//
//  Closure.swift
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

/// Represents a closure expression in Swift code.
public struct Closure: CodeBlock {
  public let capture: [ParameterExp]
  public let parameters: [ClosureParameter]
  public let returnType: String?
  public let body: [CodeBlock]
  internal var attributes: [AttributeInfo] = []

  internal var needsSignature: Bool {
    !parameters.isEmpty || returnType != nil || !capture.isEmpty || !attributes.isEmpty
  }

  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp] = { [] },
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter] = { [] },
    returns returnType: String? = nil,
    @CodeBlockBuilderResult body: () -> [CodeBlock]
  ) {
    self.capture = capture()
    self.parameters = parameters()
    self.returnType = returnType
    self.body = body()
  }

  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    let captureClause = buildCaptureClause()
    let signature = buildSignature(captureClause: captureClause)
    let bodyBlock = buildBodyBlock()

    return ExprSyntax(
      ClosureExprSyntax(
        leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
        signature: signature,
        statements: bodyBlock,
        rightBrace: .rightBraceToken(leadingTrivia: .newline)
      )
    )
  }
}
