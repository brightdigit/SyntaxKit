//
//  Function+Syntax.swift
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

extension Function {
  /// The syntax representation of this function.
  public var syntax: SyntaxProtocol {
    let funcKeyword = TokenSyntax.keyword(.func, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name)

    // Build parameter list
    let paramList = FunctionParameterListSyntax(
      parameters.enumerated().compactMap { index, param in
        // Skip empty placeholders (possible in some builder scenarios)
        guard !param.name.isEmpty || param.defaultValue != nil else { return nil }

        // Attributes for parameter
        let paramAttributes = buildAttributeList(from: param.attributes)

        let firstNameLeading: Trivia = paramAttributes.isEmpty ? [] : .space

        // Determine first & second names
        let firstNameToken: TokenSyntax
        let secondNameToken: TokenSyntax?

        if param.isUnnamed {
          firstNameToken = .wildcardToken(leadingTrivia: firstNameLeading, trailingTrivia: .space)
          secondNameToken = .identifier(param.name)
        } else if let label = param.label {
          firstNameToken = .identifier(
            label, leadingTrivia: firstNameLeading, trailingTrivia: .space)
          secondNameToken = .identifier(param.name)
        } else {
          firstNameToken = .identifier(
            param.name, leadingTrivia: firstNameLeading, trailingTrivia: .space)
          secondNameToken = nil
        }

        var paramSyntax = FunctionParameterSyntax(
          attributes: paramAttributes,
          firstName: firstNameToken,
          secondName: secondNameToken,
          colon: .colonToken(trailingTrivia: .space),
          type: IdentifierTypeSyntax(name: .identifier(param.type)),
          defaultValue: param.defaultValue.map {
            InitializerClauseSyntax(
              equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
              value: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier($0)))
            )
          }
        )
        if index < parameters.count - 1 {
          paramSyntax = paramSyntax.with(\.trailingComma, .commaToken(trailingTrivia: .space))
        }
        return paramSyntax
      })

    // Build return type if specified
    var returnClause: ReturnClauseSyntax?
    if let returnType = returnType {
      returnClause = ReturnClauseSyntax(
        arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
        type: IdentifierTypeSyntax(name: .identifier(returnType))
      )
    }

    // Build function body
    let bodyBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap {
          var item: CodeBlockItemSyntax?
          if let decl = $0.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = $0.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = $0.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return item?.with(\.trailingTrivia, .newline)
        }),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    // Build effect specifiers (async / throws)
    let effectSpecifiers: FunctionEffectSpecifiersSyntax? = {
      switch effect {
      case .none:
        return nil
      case .throws(let isRethrows, let errorType):
        let throwsSpecifier: TokenSyntax
        if let errorType = errorType {
          throwsSpecifier = .keyword(
            isRethrows ? .rethrows : .throws, leadingTrivia: .space)
          return FunctionEffectSpecifiersSyntax(
            asyncSpecifier: nil,
            throwsClause: ThrowsClauseSyntax(
              throwsSpecifier: throwsSpecifier,
              leftParen: .leftParenToken(),
              type: IdentifierTypeSyntax(name: .identifier(errorType)),
              rightParen: .rightParenToken()
            )
          )
        } else {
          throwsSpecifier = .keyword(
            isRethrows ? .rethrows : .throws, leadingTrivia: .space)
          return FunctionEffectSpecifiersSyntax(
            asyncSpecifier: nil,
            throwsSpecifier: throwsSpecifier
          )
        }
      case .async:
        return FunctionEffectSpecifiersSyntax(
          asyncSpecifier: .keyword(.async, leadingTrivia: .space, trailingTrivia: .space),
          throwsSpecifier: nil
        )
      case .asyncThrows(let isRethrows, let errorType):
        let throwsSpecifier: TokenSyntax
        if let errorType = errorType {
          throwsSpecifier = .keyword(.throws, leadingTrivia: .space)
          return FunctionEffectSpecifiersSyntax(
            asyncSpecifier: .keyword(.async, leadingTrivia: .space, trailingTrivia: .space),
            throwsClause: ThrowsClauseSyntax(
              throwsSpecifier: throwsSpecifier,
              leftParen: .leftParenToken(),
              type: IdentifierTypeSyntax(name: .identifier(errorType)),
              rightParen: .rightParenToken()
            )
          )
        } else {
          throwsSpecifier = .keyword(
            isRethrows ? .rethrows : .throws, leadingTrivia: .space)
          return FunctionEffectSpecifiersSyntax(
            asyncSpecifier: .keyword(.async, leadingTrivia: .space, trailingTrivia: .space),
            throwsSpecifier: throwsSpecifier
          )
        }
      }
    }()

    // Build modifiers
    var modifiers: DeclModifierListSyntax = []
    if isStatic {
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(.static, trailingTrivia: .space))
      ])
    }
    if isMutating {
      modifiers = DeclModifierListSyntax(
        modifiers + [
          DeclModifierSyntax(name: .keyword(.mutating, trailingTrivia: .space))
        ])
    }

    return FunctionDeclSyntax(
      attributes: buildAttributeList(from: attributes),
      modifiers: modifiers,
      funcKeyword: funcKeyword,
      name: identifier,
      genericParameterClause: nil,
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax(
          leftParen: .leftParenToken(),
          parameters: paramList,
          rightParen: .rightParenToken()
        ),
        effectSpecifiers: effectSpecifiers,
        returnClause: returnClause
      ),
      genericWhereClause: nil,
      body: bodyBlock
    )
  }

  private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    if attributes.isEmpty {
      return AttributeListSyntax([])
    }

    let attributeElements = attributes.map { attributeInfo in
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

      return AttributeListSyntax.Element(
        AttributeSyntax(
          atSign: .atSignToken(),
          attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
          leftParen: leftParen,
          arguments: argumentsSyntax,
          rightParen: rightParen
        )
      )
    }

    return AttributeListSyntax(attributeElements)
  }
}
