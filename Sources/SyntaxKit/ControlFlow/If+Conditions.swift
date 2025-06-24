//
//  If+Conditions.swift
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

extension If {
  /// Builds the conditions for the if expression.
  /// - Returns: The condition element list syntax.
  public func buildConditions() -> ConditionElementListSyntax {
    ConditionElementListSyntax(
      conditions.enumerated().map { index, block in
        let needsComma = index < conditions.count - 1
        return buildConditionElement(from: block, needsComma: needsComma)
      }
    )
  }

  /// Builds a single condition element from a code block.
  private func buildConditionElement(
    from block: CodeBlock,
    needsComma: Bool
  ) -> ConditionElementSyntax {
    let element = createConditionElement(from: block)
    return appendCommaIfNeeded(element, needsComma: needsComma)
  }

  /// Creates a condition element from a code block.
  private func createConditionElement(from block: CodeBlock) -> ConditionElementSyntax {
    if let letCond = block as? Let {
      return ConditionElementSyntax(
        condition: .optionalBinding(
          OptionalBindingConditionSyntax(
            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
            pattern: IdentifierPatternSyntax(
              identifier: .identifier(letCond.name)
            ),
            initializer: InitializerClauseSyntax(
              equal: .equalToken(
                leadingTrivia: .space,
                trailingTrivia: .space
              ),
              value: letCond.value.syntax.as(ExprSyntax.self)
                ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
            )
          )
        )
      )
    } else {
      return ConditionElementSyntax(
        condition: .expression(
          ExprSyntax(
            fromProtocol: block.syntax.as(ExprSyntax.self)
              ?? DeclReferenceExprSyntax(baseName: .identifier(""))
          )
        )
      )
    }
  }

  /// Appends a comma to the condition element if needed.
  private func appendCommaIfNeeded(
    _ element: ConditionElementSyntax,
    needsComma: Bool
  ) -> ConditionElementSyntax {
    needsComma ? element.with(\.trailingComma, .commaToken(trailingTrivia: .space)) : element
  }
}
