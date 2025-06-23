//
//  Variable+Attributes.swift
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

/// Represents attribute arguments for variable declarations.
private struct AttributeArguments {
  let leftParen: TokenSyntax?
  let rightParen: TokenSyntax?
  let arguments: AttributeSyntax.Arguments?

  init(
    leftParen: TokenSyntax? = nil,
    rightParen: TokenSyntax? = nil,
    arguments: AttributeSyntax.Arguments? = nil
  ) {
    self.leftParen = leftParen
    self.rightParen = rightParen
    self.arguments = arguments
  }
}

extension Variable {
  /// Builds the attribute list for the variable declaration.
  internal func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    guard !attributes.isEmpty else {
      return AttributeListSyntax([])
    }

    let attributeElements = attributes.map(buildAttributeElement)
    return AttributeListSyntax(attributeElements)
  }

  /// Builds an attribute element from attribute info.
  private func buildAttributeElement(from attributeInfo: AttributeInfo)
    -> AttributeListSyntax.Element
  {
    let attributeArgs = buildAttributeArguments(from: attributeInfo.arguments)

    return AttributeListSyntax.Element(
      AttributeSyntax(
        atSign: .atSignToken(),
        attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
        leftParen: attributeArgs.leftParen,
        arguments: attributeArgs.arguments,
        rightParen: attributeArgs.rightParen
      )
    )
  }

  /// Builds attribute arguments from a string array.
  private func buildAttributeArguments(from arguments: [String]) -> AttributeArguments {
    guard !arguments.isEmpty else {
      return AttributeArguments()
    }

    let leftParen: TokenSyntax = .leftParenToken()
    let rightParen: TokenSyntax = .rightParenToken()

    let argumentList = arguments.map { argument in
      DeclReferenceExprSyntax(baseName: .identifier(argument))
    }

    let argumentsSyntax = AttributeSyntax.Arguments.argumentList(
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

    return AttributeArguments(
      leftParen: leftParen,
      rightParen: rightParen,
      arguments: argumentsSyntax
    )
  }
}
