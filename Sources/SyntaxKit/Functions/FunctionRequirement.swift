//
//  FunctionRequirement.swift
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

/// A function requirement within a protocol declaration (no body).
public struct FunctionRequirement: CodeBlock {
  private let name: String
  private let parameters: [Parameter]
  private let returnType: String?
  private var isStatic: Bool = false
  private var isMutating: Bool = false

  /// Creates a parameterless function requirement.
  /// - Parameters:
  ///   - name: The function name.
  ///   - returnType: Optional return type.
  public init(_ name: String, returns returnType: String? = nil) {
    self.name = name
    self.parameters = []
    self.returnType = returnType
  }

  /// Creates a function requirement with parameters.
  /// - Parameters:
  ///   - name: The function name.
  ///   - returnType: Optional return type.
  ///   - params: A ParameterBuilderResult providing the parameters.
  public init(
    _ name: String,
    returns returnType: String? = nil,
    @ParameterBuilderResult _ params: () -> [Parameter]
  ) {
    self.name = name
    self.parameters = params()
    self.returnType = returnType
  }

  /// Marks the function requirement as `static`.
  public func `static`() -> Self {
    var copy = self
    copy.isStatic = true
    return copy
  }

  /// Marks the function requirement as `mutating`.
  public func mutating() -> Self {
    var copy = self
    copy.isMutating = true
    return copy
  }

  public var syntax: SyntaxProtocol {
    let funcKeyword = TokenSyntax.keyword(.func, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name)

    // Parameters
    let paramList: FunctionParameterListSyntax
    if parameters.isEmpty {
      paramList = FunctionParameterListSyntax([])
    } else {
      paramList = FunctionParameterListSyntax(
        parameters.enumerated().compactMap { index, param in
          guard !param.name.isEmpty else {
            return nil
          }
          var paramSyntax = FunctionParameterSyntax(
            firstName: param.isUnnamed
              ? .wildcardToken(trailingTrivia: .space) : .identifier(param.name),
            secondName: param.isUnnamed ? .identifier(param.name) : nil,
            colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
            type: param.type.typeSyntax,
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
        }
      )
    }

    // Return clause
    var returnClause: ReturnClauseSyntax?
    if let returnType = returnType {
      returnClause = ReturnClauseSyntax(
        arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
        type: IdentifierTypeSyntax(name: .identifier(returnType))
      )
    }

    // Modifiers
    var modifiers: DeclModifierListSyntax = []
    if isStatic {
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(.static, trailingTrivia: .space))
      ])
    }
    if isMutating {
      modifiers = DeclModifierListSyntax(
        modifiers + [DeclModifierSyntax(name: .keyword(.mutating, trailingTrivia: .space))]
      )
    }

    return FunctionDeclSyntax(
      attributes: AttributeListSyntax([]),
      modifiers: modifiers,
      funcKeyword: funcKeyword,
      name: identifier,
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax(
          leftParen: .leftParenToken(), parameters: paramList, rightParen: .rightParenToken()
        ),
        effectSpecifiers: nil,
        returnClause: returnClause
      ),
      body: nil
    )
  }
}
