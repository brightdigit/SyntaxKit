//
//  Function.swift
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

/// A Swift `func` declaration.
public struct Function: CodeBlock {
  internal let name: String
  internal let parameters: [Parameter]
  internal let returnType: String?
  internal let body: [CodeBlock]
  internal var isStatic: Bool = false
  internal var isMutating: Bool = false
  internal var effect: Effect = .none
  internal var attributes: [AttributeInfo] = []

  /// Creates a `func` declaration.
  /// - Parameters:
  ///   - name: The name of the function.
  ///   - returnType: The return type of the function, if any.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the function.
  public init(
    _ name: String, returns returnType: String? = nil,
    @CodeBlockBuilderResult _ content: () -> [CodeBlock]
  ) {
    self.name = name
    self.parameters = []
    self.returnType = returnType
    self.body = content()
  }

  /// Creates a `func` declaration.
  /// - Parameters:
  ///   - name: The name of the function.
  ///   - returnType: The return type of the function, if any.
  ///   - params: A ``ParameterBuilder`` that provides the parameters of the function.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the function.
  public init(
    _ name: String, returns returnType: String? = nil,
    @ParameterBuilderResult _ params: () -> [Parameter],
    @CodeBlockBuilderResult _ content: () -> [CodeBlock]
  ) {
    self.name = name
    self.parameters = params()
    self.returnType = returnType
    self.body = content()
  }

  /// Creates a `func` declaration with parameters and body using the DSL syntax.
  /// - Parameters:
  ///   - name: The name of the function.
  ///   - params: A ``ParameterBuilder`` that provides the parameters of the function.
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the function.
  public init(
    _ name: String,
    @ParameterBuilderResult _ params: () -> [Parameter],
    @CodeBlockBuilderResult _ body: () -> [CodeBlock]
  ) {
    self.name = name
    self.parameters = params()
    self.returnType = nil
    self.body = body()
  }
}
