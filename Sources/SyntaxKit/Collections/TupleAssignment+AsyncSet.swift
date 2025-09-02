//
//  TupleAssignment+AsyncSet.swift
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

extension TupleAssignment {
  internal enum AsyncSet {
    internal static func tuplePattern(elements: [String]) -> PatternSyntax {
      let patternElements = TuplePatternElementListSyntax(
        elements.enumerated().map { index, element in
          TuplePatternElementSyntax(
            label: nil,
            colon: nil,
            pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(element))),
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
          )
        }
      )
      return PatternSyntax(
        TuplePatternSyntax(
          leftParen: .leftParenToken(),
          elements: patternElements,
          rightParen: .rightParenToken()
        )
      )
    }

    internal static func tupleExpr(tuple: Tuple) -> ExprSyntax {
      ExprSyntax(
        TupleExprSyntax(
          leftParen: .leftParenToken(),
          elements: LabeledExprListSyntax(
            tuple.elements.enumerated().map { index, block in
              LabeledExprSyntax(
                label: nil,
                colon: nil,
                expression: block.expr,
                trailingComma: index < tuple.elements.count - 1
                  ? .commaToken(trailingTrivia: .space) : nil
              )
            }
          ),
          rightParen: .rightParenToken()
        )
      )
    }

    internal static func valueExpr(tupleExpr: ExprSyntax, isThrowing: Bool) -> ExprSyntax {
      isThrowing
        ? ExprSyntax(
          TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: ExprSyntax(
              AwaitExprSyntax(
                awaitKeyword: .keyword(.await, trailingTrivia: .space),
                expression: tupleExpr
              )
            )
          )
        )
        : ExprSyntax(
          AwaitExprSyntax(
            awaitKeyword: .keyword(.await, trailingTrivia: .space),
            expression: tupleExpr
          )
        )
    }
  }
}
