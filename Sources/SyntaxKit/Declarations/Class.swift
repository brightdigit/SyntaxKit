//
//  Class.swift
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

/// A Swift `class` declaration.
public struct Class: CodeBlock, Sendable {
  private let name: String
  private let members: [any CodeBlock]
  private var inheritance: [String] = []
  private var genericParameters: [String] = []
  private var isFinal: Bool = false
  private var attributes: [AttributeInfo] = []

  /// Creates a class declaration.
  /// - Parameters:
  ///   - name: The name of the class.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the class.
  public init(_ name: String, @CodeBlockBuilderResult _ content: () throws -> [any CodeBlock])
    rethrows
  {
    self.name = name
    self.members = try content()
  }

  /// Sets the generic parameters for the class.
  /// - Parameter generics: The list of generic parameter names.
  /// - Returns: A copy of the class with the generic parameters set.
  public func generic(_ generics: String...) -> Self {
    var copy = self
    copy.genericParameters = generics
    return copy
  }

  /// Sets the inheritance for the class.
  /// - Parameter inheritance: The types to inherit from.
  /// - Returns: A copy of the class with the inheritance set.
  public func inherits(_ inheritance: String...) -> Self {
    var copy = self
    copy.inheritance = inheritance
    return copy
  }

  /// Marks the class declaration as `final`.
  /// - Returns: A copy of the class marked as `final`.
  public func final() -> Self {
    var copy = self
    copy.isFinal = true
    return copy
  }

  /// Adds an attribute to the class declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the class with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: any SyntaxProtocol {
    let classKeyword = TokenSyntax.keyword(.class, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name)

    // Build attributes
    let attributeList = buildAttributeList(from: attributes)

    // Generic parameter clause
    var genericParameterClause: GenericParameterClauseSyntax?
    if !genericParameters.isEmpty {
      let parameterList = GenericParameterListSyntax(
        genericParameters.enumerated().map { idx, name in
          var param = GenericParameterSyntax(name: .identifier(name))
          if idx < genericParameters.count - 1 {
            param = param.with(
              \.trailingComma,
              TokenSyntax.commaToken(trailingTrivia: .space)
            )
          }
          return param
        }
      )
      genericParameterClause = GenericParameterClauseSyntax(
        leftAngle: .leftAngleToken(),
        parameters: parameterList,
        rightAngle: .rightAngleToken()
      )
    }

    // Inheritance clause
    var inheritanceClause: InheritanceClauseSyntax?
    if !inheritance.isEmpty {
      let inheritedTypes = inheritance.map { type in
        InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(type)))
      }
      inheritanceClause = InheritanceClauseSyntax(
        colon: .colonToken(),
        inheritedTypes: InheritedTypeListSyntax(
          inheritedTypes.enumerated().map { idx, inherited in
            var inheritedType = inherited
            if idx < inheritedTypes.count - 1 {
              inheritedType = inheritedType.with(
                \.trailingComma,
                TokenSyntax.commaToken(trailingTrivia: .space)
              )
            }
            return inheritedType
          }
        )
      )
    }

    // Member block
    let memberBlock = MemberBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      members: MemberBlockItemListSyntax(
        members.compactMap { member in
          guard let decl = member.syntax.as(DeclSyntax.self) else {
            return nil
          }
          return MemberBlockItemSyntax(decl: decl, trailingTrivia: .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    // Modifiers
    var modifiers: DeclModifierListSyntax = []
    if isFinal {
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(.final, trailingTrivia: .space))
      ])
    }

    return ClassDeclSyntax(
      attributes: attributeList,
      modifiers: modifiers,
      classKeyword: classKeyword,
      name: identifier,
      genericParameterClause: genericParameterClause,
      inheritanceClause: inheritanceClause,
      memberBlock: memberBlock
    )
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
