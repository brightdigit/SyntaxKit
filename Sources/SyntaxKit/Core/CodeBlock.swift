//
//  CodeBlock.swift
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

import Foundation
public import SwiftSyntax

/// A protocol for types that can be represented as a SwiftSyntax node.
public protocol CodeBlock: PatternConvertible, Sendable {
  /// The SwiftSyntax representation of the code block.
  var syntax: SyntaxProtocol { get }

  /// Calls a method on this code block with the given name and parameters.
  /// - Parameters:
  ///   - name: The name of the method to call.
  ///   - parameters: A closure that returns the parameters for the method call.
  /// - Returns: A code block representing the method call.
  func call(_ name: String, @ParameterExpBuilderResult _ parameters: () -> [ParameterExp])
    -> CodeBlock
}

extension CodeBlock {
  /// Calls a method on this code block with the given name and parameters.
  /// - Parameters:
  ///   - name: The name of the method to call.
  ///   - parameters: A closure that returns the parameters for the method call.
  /// - Returns: A code block representing the method call.
  public func call(
    _ name: String, @ParameterExpBuilderResult _ parameters: () -> [ParameterExp] = { [] }
  ) -> CodeBlock {
    FunctionCallExp(base: self, methodName: name, parameters: parameters())
  }

  /// The pattern syntax representation of this code block.
  public var patternSyntax: PatternSyntax {
    let expr = ExprSyntax(
      fromProtocol: self.syntax.as(ExprSyntax.self)
        ?? DeclReferenceExprSyntax(baseName: .identifier(""))
    )
    return PatternSyntax(ExpressionPatternSyntax(expression: expr))
  }
}
