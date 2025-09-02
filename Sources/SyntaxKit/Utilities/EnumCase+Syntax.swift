//
//  EnumCase+Syntax.swift
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

extension EnumCase {
  /// Returns the appropriate syntax based on context.
  /// When used in expressions (throw, return, if bodies), returns expression syntax.
  /// When used in declarations (enum cases), returns declaration syntax.
  public var syntax: any SyntaxProtocol {
    // For enum case declarations, return EnumCaseDeclSyntax
    let caseKeyword = TokenSyntax.keyword(.case, trailingTrivia: .space)

    // Create the enum case element
    var enumCaseElement = EnumCaseElementSyntax(
      name: .identifier(name, trailingTrivia: .space)
    )

    // Add raw value if present
    if let literalValue = literalValue {
      let valueSyntax =
        literalValue.syntax.as(ExprSyntax.self)
        ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
      enumCaseElement = enumCaseElement.with(
        \.rawValue,
        .init(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: valueSyntax
        )
      )
    }

    // Add associated values if present
    if !associatedValues.isEmpty {
      let parameters = associatedValues.enumerated().map { index, associated in
        var parameter = EnumCaseParameterSyntax(
          firstName: nil,
          secondName: .identifier(associated.name),
          colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
          type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(associated.type)))
        )

        if index < associatedValues.count - 1 {
          parameter = parameter.with(\.trailingComma, .commaToken(trailingTrivia: .space))
        }

        return parameter
      }

      enumCaseElement = enumCaseElement.with(
        \.parameterClause,
        .init(
          leftParen: .leftParenToken(),
          parameters: EnumCaseParameterListSyntax(parameters),
          rightParen: .rightParenToken()
        )
      )
    }

    return EnumCaseDeclSyntax(
      caseKeyword: caseKeyword,
      elements: EnumCaseElementListSyntax([enumCaseElement])
    )
  }
}
