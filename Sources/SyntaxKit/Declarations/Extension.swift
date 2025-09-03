//
//  Extension.swift
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

/// A Swift `extension` declaration.
public struct Extension: CodeBlock, Sendable {
  private let extendedType: String
  private let members: [any CodeBlock]
  private var inheritance: [String] = []
  private var attributes: [AttributeInfo] = []

  public var syntax: any SyntaxProtocol {
    let extensionKeyword = TokenSyntax.keyword(.extension, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(extendedType, trailingTrivia: .space)

    var inheritanceClause: InheritanceClauseSyntax?
    if !inheritance.isEmpty {
      let inheritedTypes = inheritance.map { type in
        InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(type)))
      }
      inheritanceClause = InheritanceClauseSyntax(
        colon: .colonToken(),
        inheritedTypes: InheritedTypeListSyntax(
          inheritedTypes.enumerated().map { idx, inherited in
            var type = inherited
            if idx < inheritedTypes.count - 1 {
              type = type.with(\.trailingComma, TokenSyntax.commaToken(trailingTrivia: .space))
            }
            return type
          }
        )
      )
    }

    let memberBlock = MemberBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      members: MemberBlockItemListSyntax(
        members.compactMap { member in
          guard let syntax = member.syntax.as(DeclSyntax.self) else {
            return nil
          }
          return MemberBlockItemSyntax(decl: syntax, trailingTrivia: .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    return ExtensionDeclSyntax(
      attributes: buildAttributeList(from: attributes),
      extensionKeyword: extensionKeyword,
      extendedType: IdentifierTypeSyntax(name: identifier),
      inheritanceClause: inheritanceClause,
      memberBlock: memberBlock
    )
  }

  /// Creates an extension declaration.
  /// - Parameters:
  ///   - extendedType: The type being extended.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the extension.
  public init(
    _ extendedType: String, @CodeBlockBuilderResult _ content: () throws -> [any CodeBlock]
  )
    rethrows
  {
    self.extendedType = extendedType
    self.members = try content()
  }

  /// Sets one or more inherited protocols.
  /// - Parameter types: The list of protocols this extension conforms to.
  /// - Returns: A copy of the extension with the inheritance set.
  public func inherits(_ types: String...) -> Self {
    var copy = self
    copy.inheritance = types
    return copy
  }

  /// Adds an attribute to the extension declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the extension with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    if attributes.isEmpty {
      return AttributeListSyntax([])
    }
    let attributeElements = attributes.map { attribute in
      let arguments = attribute.arguments

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

      return AttributeListSyntax.Element(
        AttributeSyntax(
          atSign: .atSignToken(),
          attributeName: IdentifierTypeSyntax(name: .identifier(attribute.name)),
          leftParen: leftParen,
          arguments: argumentsSyntax,
          rightParen: rightParen
        )
      )
    }
    return AttributeListSyntax(attributeElements)
  }
}
