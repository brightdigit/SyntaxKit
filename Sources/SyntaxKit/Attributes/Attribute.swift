//
//  Attribute.swift
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

public import SwiftSyntax

/// A Swift attribute that can be used as a property wrapper.
public struct Attribute: CodeBlock {
  private let name: String
  private let arguments: [String]

  /// Creates an attribute with the given name and optional arguments.
  /// - Parameters:
  ///   - name: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  public init(_ name: String, arguments: [String] = []) {
    self.name = name
    self.arguments = arguments
  }

  /// Creates an attribute with a name and a single argument.
  /// - Parameters:
  ///   - name: The name of the attribute (without the @ symbol).
  ///   - argument: The argument for the attribute.
  public init(_ name: String, argument: String) {
    self.name = name
    self.arguments = [argument]
  }

  public var syntax: any SyntaxProtocol {
    var leftParen: TokenSyntax?
    var rightParen: TokenSyntax?
    var argumentsSyntax: AttributeSyntax.Arguments?

    if !arguments.isEmpty {
      leftParen = .leftParenToken()
      rightParen = .rightParenToken()

      let argumentList = arguments.map { argument in
        DeclReferenceExprSyntax(baseName: .identifier(argument))
      }

      argumentsSyntax = .argumentList(
        LabeledExprListSyntax(
          argumentList.enumerated().map { index, expr in
            var element = LabeledExprSyntax(expression: ExprSyntax(expr))
            if index < argumentList.count - 1 {
              element = element.with(\.trailingComma, .commaToken(trailingTrivia: .space))
            }
            return element
          }
        )
      )
    }

    return AttributeSyntax(
      atSign: .atSignToken(),
      attributeName: IdentifierTypeSyntax(name: .identifier(name)),
      leftParen: leftParen,
      arguments: argumentsSyntax,
      rightParen: rightParen
    )
  }
}
