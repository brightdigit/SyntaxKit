//
//  Literal+ExprCodeBlock.swift
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

// MARK: - ExprCodeBlock conformance

extension Literal: ExprCodeBlock {
  /// The expression syntax representation of this literal.
  public var exprSyntax: ExprSyntax {
    switch self {
    case .string(let value):
      return ExprSyntax(
        StringLiteralExprSyntax(
          openingQuote: .stringQuoteToken(),
          segments: .init(
            [
              .stringSegment(.init(content: .stringSegment(value)))
            ]
          ),
          closingQuote: .stringQuoteToken()
        )
      )
    case .float(let value):
      return ExprSyntax(FloatLiteralExprSyntax(literal: .floatLiteral(String(value))))
    case .integer(let value):
      return ExprSyntax(IntegerLiteralExprSyntax(digits: .integerLiteral(String(value))))
    case .nil:
      return ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil)))
    case .boolean(let value):
      return ExprSyntax(
        BooleanLiteralExprSyntax(
          literal: value ? .keyword(.true) : .keyword(.false)
        )
      )
    case .ref(let value):
      return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(value)))
    case .tuple(let elements):
      let tupleElements = TupleExprElementListSyntax(
        elements.enumerated().map { index, element in
          let elementExpr: ExprSyntax
          if let element = element {
            elementExpr = element.exprSyntax
          } else {
            // Wildcard pattern - use underscore
            elementExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("_")))
          }
          return TupleExprElementSyntax(
            label: nil,
            colon: nil,
            expression: elementExpr,
            trailingComma: index < elements.count - 1
              ? .commaToken(trailingTrivia: .space)
              : nil
          )
        }
      )
      return ExprSyntax(
        TupleExprSyntax(
          leftParen: .leftParenToken(),
          elements: tupleElements,
          rightParen: .rightParenToken()
        )
      )
    case .array(let elements):
      let arrayElements = ArrayElementListSyntax(
        elements.enumerated().map { index, element in
          ArrayElementSyntax(
            expression: element.syntax.as(ExprSyntax.self)
              ?? ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier(""))
              ),
            trailingComma: index < elements.count - 1
              ? .commaToken(trailingTrivia: .space)
              : nil
          )
        }
      )
      return ExprSyntax(ArrayExprSyntax(elements: arrayElements))
    case .dictionary(let elements):
      if elements.isEmpty {
        // Empty dictionary should generate [:]
        return ExprSyntax(
          DictionaryExprSyntax(
            leftSquare: .leftSquareToken(),
            content: .colon(
              .colonToken(
                leadingTrivia: .init(),
                trailingTrivia: .init()
              )
            ),
            rightSquare: .rightSquareToken()
          )
        )
      } else {
        let dictionaryElements = DictionaryElementListSyntax(
          elements.enumerated().map { index, keyValue in
            let (key, value) = keyValue
            return DictionaryElementSyntax(
              keyExpression: key.exprSyntax,
              colon: .colonToken(),
              valueExpression: value.exprSyntax,
              trailingComma: index < elements.count - 1
                ? .commaToken(trailingTrivia: .space)
                : nil
            )
          }
        )
        return ExprSyntax(
          DictionaryExprSyntax(
            content: .elements(dictionaryElements)
          )
        )
      }
    }
  }
}
