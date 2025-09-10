//
//  FunctionParameterSyntax+Init.swift
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

extension FunctionParameterSyntax {
  /// Private struct to hold parameter name tokens.
  private struct ParameterNames {
    let firstNameToken: TokenSyntax
    let secondNameToken: TokenSyntax?

    /// Creates parameter name tokens from a parameter.
    /// - Parameters:
    ///   - parameter: The parameter to create tokens for.
    ///   - firstNameLeading: The leading trivia for the first name token.
    init(from parameter: Parameter, firstNameLeading: Trivia) {
      if parameter.isUnnamed {
        self.firstNameToken = .wildcardToken(
          leadingTrivia: firstNameLeading,
          trailingTrivia: .space
        )
        self.secondNameToken = .identifier(parameter.name)
      } else if let label = parameter.label {
        self.firstNameToken = .identifier(
          label,
          leadingTrivia: firstNameLeading,
          trailingTrivia: .space
        )
        self.secondNameToken = .identifier(parameter.name)
      } else {
        self.firstNameToken = .identifier(
          parameter.name,
          leadingTrivia: firstNameLeading,
          trailingTrivia: .space
        )
        self.secondNameToken = nil
      }
    }
  }

  /// Creates a `FunctionParameterSyntax` from a `Parameter`.
  /// - Parameters:
  ///   - parameter: The parameter to convert.
  ///   - attributes: The attributes for the parameter.
  ///   - isLast: Whether this is the last parameter in the list.
  /// - Returns: A `FunctionParameterSyntax` if the conversion is successful, `nil` otherwise.
  public static func create(
    from parameter: Parameter,
    attributes: AttributeListSyntax,
    isLast: Bool
  ) -> FunctionParameterSyntax? {
    // Skip empty placeholders (possible in some builder scenarios)
    guard !parameter.name.isEmpty || parameter.defaultValue != nil else {
      return nil
    }

    let firstNameLeading: Trivia = attributes.isEmpty ? [] : .space
    let parameterNames = ParameterNames(from: parameter, firstNameLeading: firstNameLeading)

    var paramSyntax = FunctionParameterSyntax(
      attributes: attributes,
      firstName: parameterNames.firstNameToken,
      secondName: parameterNames.secondNameToken,
      colon: .colonToken(trailingTrivia: .space),
      type: parameter.type.typeSyntax,
      defaultValue: parameter.defaultValue.map {
        InitializerClauseSyntax(
          equal: .equalToken(
            leadingTrivia: .space,
            trailingTrivia: .space
          ),
          value: ExprSyntax(
            DeclReferenceExprSyntax(baseName: .identifier($0))
          )
        )
      }
    )

    if !isLast {
      paramSyntax = paramSyntax.with(
        \.trailingComma,
        TokenSyntax.commaToken(trailingTrivia: .space)
      )
    }

    return paramSyntax
  }
}
