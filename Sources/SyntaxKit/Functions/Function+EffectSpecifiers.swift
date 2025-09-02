//
//  Function+EffectSpecifiers.swift
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

extension Function {
  /// Builds the effect specifiers (async / throws) for the function.
  internal func buildEffectSpecifiers() -> FunctionEffectSpecifiersSyntax? {
    switch effect {
    case .none:
      return nil
    case let .throws(isRethrows, errorType):
      let throwsSpecifier = buildThrowsSpecifier(isRethrows: isRethrows)
      if let errorType = errorType {
        return FunctionEffectSpecifiersSyntax(
          asyncSpecifier: nil,
          throwsClause: buildThrowsClause(throwsSpecifier: throwsSpecifier, errorType: errorType)
        )
      } else {
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
    case let .asyncThrows(isRethrows, errorType):
      let throwsSpecifier = buildThrowsSpecifier(isRethrows: isRethrows)
      if let errorType = errorType {
        return FunctionEffectSpecifiersSyntax(
          asyncSpecifier: .keyword(.async, leadingTrivia: .space, trailingTrivia: .space),
          throwsClause: buildThrowsClause(throwsSpecifier: throwsSpecifier, errorType: errorType)
        )
      } else {
        return FunctionEffectSpecifiersSyntax(
          asyncSpecifier: .keyword(.async, leadingTrivia: .space, trailingTrivia: .space),
          throwsSpecifier: throwsSpecifier
        )
      }
    }
  }

  /// Builds the throws specifier token.
  private func buildThrowsSpecifier(isRethrows: Bool) -> TokenSyntax {
    .keyword(isRethrows ? .rethrows : .throws, leadingTrivia: .space)
  }

  /// Builds the throws clause with error type.
  private func buildThrowsClause(throwsSpecifier: TokenSyntax, errorType: String)
    -> ThrowsClauseSyntax
  {
    ThrowsClauseSyntax(
      throwsSpecifier: throwsSpecifier,
      leftParen: .leftParenToken(),
      type: IdentifierTypeSyntax(name: .identifier(errorType)),
      rightParen: .rightParenToken()
    )
  }
}
