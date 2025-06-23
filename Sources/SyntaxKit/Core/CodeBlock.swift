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
import SwiftSyntax

/// A protocol for types that can be represented as a SwiftSyntax node.
public protocol CodeBlock {
  /// The SwiftSyntax representation of the code block.
  var syntax: SyntaxProtocol { get }
  
  /// Calls a method on this code block.
  /// - Parameters:
  ///   - methodName: The name of the method to call.
  ///   - params: A closure that returns the parameters for the method call.
  /// - Returns: A FunctionCallExp representing the method call.
  func call(_ methodName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp]) -> CodeBlock
}

extension CodeBlock {
  public func call(_ methodName: String, @ParameterExpBuilderResult _ params: () -> [ParameterExp] = { [] }) -> CodeBlock {
    FunctionCallExp(base: self, methodName: methodName, parameters: params())
  }
}

public protocol TypeRepresentable {
    var typeSyntax: TypeSyntax { get }
}

extension String: TypeRepresentable {
    public var typeSyntax: TypeSyntax { TypeSyntax(IdentifierTypeSyntax(name: .identifier(self))) }
}
