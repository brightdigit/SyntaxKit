//
//  ClosureType.swift
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

/// A Swift closure type (e.g., `(Date) -> Void`).
public struct ClosureType: CodeBlock, TypeRepresentable {
  private let parameters: [ClosureParameter]
  private let returnType: String?
  private var attributes: [AttributeInfo] = []

  /// Creates a closure type with no parameters.
  /// - Parameter returns: The return type of the closure.
  public init(returns returnType: String? = nil) {
    self.parameters = []
    self.returnType = returnType
  }

  /// Creates a closure type with parameters.
  /// - Parameters:
  ///   - returns: The return type of the closure.
  ///   - parameters: A ``ClosureParameterBuilderResult`` that provides the parameters.
  internal init(
    returns returnType: String? = nil,
    @ClosureParameterBuilderResult _ parameters: () -> [ClosureParameter]
  ) {
    self.parameters = parameters()
    self.returnType = returnType
  }

  /// Adds an attribute to the closure type.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the closure type with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    // Build parameters
    let paramList = parameters.map { param in
      TupleTypeElementSyntax(
        type: param.type.map { IdentifierTypeSyntax(name: .identifier($0)) }
          ?? IdentifierTypeSyntax(name: .identifier("Any"))
      )
    }

    // Build return clause
    var returnClause: ReturnClauseSyntax?
    if let returnType = returnType {
      returnClause = ReturnClauseSyntax(
        arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
        type: IdentifierTypeSyntax(name: .identifier(returnType))
      )
    }

    // Build function type
    let functionType = FunctionTypeSyntax(
      leftParen: .leftParenToken(),
      parameters: TupleTypeElementListSyntax(paramList),
      rightParen: .rightParenToken(),
      effectSpecifiers: nil,
      returnClause: returnClause
        ?? ReturnClauseSyntax(
          arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
          type: IdentifierTypeSyntax(name: .identifier("Void"))
        )
    )

    // Build attributed type if there are attributes
    if !attributes.isEmpty {
      return AttributedTypeSyntax(
        specifiers: TypeSpecifierListSyntax([]),
        attributes: buildAttributeList(from: attributes),
        baseType: functionType
      )
    } else {
      return functionType
    }
  }

  private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    if attributes.isEmpty {
      return AttributeListSyntax([])
    }
    let attributeElements = attributes.enumerated().map { index, attributeInfo in
      let arguments = attributeInfo.arguments

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

      // Add leading space for all but the first attribute
      let atSign =
        index == 0 ? TokenSyntax.atSignToken() : TokenSyntax.atSignToken(leadingTrivia: .space)

      return AttributeListSyntax.Element(
        AttributeSyntax(
          atSign: atSign,
          attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
          leftParen: leftParen,
          arguments: argumentsSyntax,
          rightParen: rightParen
        ).with(\.trailingTrivia, index == attributes.count - 1 ? .space : Trivia())
      )
    }
    return AttributeListSyntax(attributeElements)
  }

  /// A string representation of the closure type.
  public var description: String {
    let params = parameters.map { param in
      if let type = param.type {
        return "\(param.name): \(type)"
      } else {
        return param.name
      }
    }
    .joined(separator: ", ")
    let attr = attributes.map { "@\($0.name)" }.joined(separator: " ")
    let paramList = "(\(params))"
    let ret = returnType ?? "Void"
    let typeString = "\(paramList) -> \(ret)"
    return attr.isEmpty ? typeString : "\(attr) \(typeString)"
  }

  /// The SwiftSyntax representation of this closure type.
  public var typeSyntax: TypeSyntax {
    // Build parameters
    let paramList = parameters.map { param in
      TupleTypeElementSyntax(
        type: param.type.map { IdentifierTypeSyntax(name: .identifier($0)) }
          ?? IdentifierTypeSyntax(name: .identifier(param.name))
      )
    }
    // Build return clause
    var returnClause: ReturnClauseSyntax?
    if let returnType = returnType {
      returnClause = ReturnClauseSyntax(
        arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
        type: IdentifierTypeSyntax(name: .identifier(returnType))
      )
    }

    // Build function type
    let functionType = FunctionTypeSyntax(
      leftParen: .leftParenToken(),
      parameters: TupleTypeElementListSyntax(paramList),
      rightParen: .rightParenToken(),
      effectSpecifiers: nil,
      returnClause: returnClause
        ?? ReturnClauseSyntax(
          arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
          type: IdentifierTypeSyntax(name: .identifier("Void"))
        )
    )

    // Apply attributes if any
    if !attributes.isEmpty {
      return TypeSyntax(
        AttributedTypeSyntax(
          specifiers: TypeSpecifierListSyntax([]),
          attributes: buildAttributeList(from: attributes),
          baseType: TypeSyntax(functionType)
        )
      )
    } else {
      return TypeSyntax(functionType)
    }
  }
}
