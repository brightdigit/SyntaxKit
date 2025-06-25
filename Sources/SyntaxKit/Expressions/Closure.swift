//
//  Closure.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
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

  /// Creates a closure with all parameters.
  /// - Parameters:
  ///   - capture: A ``ParameterExpBuilderResult`` that provides the capture list.
  ///   - parameters: A ``ClosureParameterBuilderResult`` that provides the closure parameters.
  ///   - returnType: The return type of the closure.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp],
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter],
    returns returnType: String?,
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    self.capture = capture()
    self.parameters = parameters()
    self.returnType = returnType
    self.body = try body()
  }

  /// Creates a closure without a return type.
  /// - Parameters:
  ///   - capture: A ``ParameterExpBuilderResult`` that provides the capture list.
  ///   - parameters: A ``ClosureParameterBuilderResult`` that provides the closure parameters.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp],
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter],
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(capture: capture, parameters: parameters, returns: nil, body: body)
  }

  /// Creates a closure without parameters.
  /// - Parameters:
  ///   - capture: A ``ParameterExpBuilderResult`` that provides the capture list.
  ///   - returnType: The return type of the closure.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp],
    returns returnType: String?,
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: capture,
      parameters: [ClosureParameter].init,
      returns: returnType,
      body: body
    )
  }

  /// Creates a closure without parameters and return type.
  /// - Parameters:
  ///   - capture: A ``ParameterExpBuilderResult`` that provides the capture list.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ParameterExpBuilderResult capture: () -> [ParameterExp],
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: capture,
      parameters: [ClosureParameter].init,
      returns: nil,
      body: body
    )
  }

  /// Creates a closure without capture list and return type.
  /// - Parameters:
  ///   - parameters: A ``ClosureParameterBuilderResult`` that provides the closure parameters.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter],
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: [ParameterExp].init,
      parameters: parameters,
      returns: nil,
      body: body
    )
  }

  /// Creates a closure without capture list.
  /// - Parameters:
  ///   - parameters: A ``ClosureParameterBuilderResult`` that provides the closure parameters.
  ///   - returnType: The return type of the closure.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @ClosureParameterBuilderResult parameters: () -> [ClosureParameter],
    returns returnType: String?,
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: [ParameterExp].init,
      parameters: parameters,
      returns: returnType,
      body: body
    )
  }

  /// Creates a simple closure with only a body.
  /// - Parameters:
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: [ParameterExp].init,
      parameters: [ClosureParameter].init,
      returns: nil,
      body: body
    )
  }

  /// Creates a closure without capture list and parameters.
  /// - Parameters:
  ///   - returnType: The return type of the closure.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the closure.
  public init(
    returns returnType: String?,
    @CodeBlockBuilderResult body: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      capture: [ParameterExp].init,
      parameters: [ClosureParameter].init,
      returns: returnType,
      body: body
    )
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
