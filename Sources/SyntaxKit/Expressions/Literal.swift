//
//  Literal.swift
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

/// Represents Swift literal values.
public enum Literal: CodeBlock, CodeBlockable, Sendable {
  /// A string literal.
  case string(String)
  /// A floating-point literal.
  case float(Double)
  /// An integer literal.
  case integer(Int)
  /// A `nil` literal.
  case `nil`
  /// A boolean literal.
  case boolean(Bool)
  /// A reference to a variable or identifier (outputs without quotes).
  case ref(String)
  /// A tuple literal.
  case tuple([Literal?])
  /// An array literal.
  case array([Literal])
  /// A dictionary literal.
  case dictionary([(Literal, Literal)])

  /// The code block representation of this literal.
  public var codeBlock: CodeBlock {
    self
  }

  /// The Swift type name for this literal.
  public var typeName: String {
    switch self {
    case .string: return "String"
    case .float: return "Double"
    case .integer: return "Int"
    case .nil: return "Any?"
    case .boolean: return "Bool"
    // TODO: Consider more specific type inference for ref cases
    case .ref: return "Any"
    case .tuple(let elements):
      let elementTypes = elements.map { element in
        if let element = element {
          switch element {
          case .integer: return "Int"
          case .float: return "Double"
          case .string: return "String"
          case .boolean: return "Bool"
          case .nil: return "Any?"
          // TODO: Consider more specific type inference for ref cases
          case .ref: return "Any"
          // TODO: Consider more specific type inference for complex literals
          case .tuple: return "Any"
          case .array: return "Any"
          case .dictionary: return "Any"
          }
        } else {
          return "Any"
        }
      }
      return "(\(elementTypes.joined(separator: ", ")))"
    case .array(let elements):
      if elements.isEmpty {
        // TODO: Consider more specific type inference for empty arrays
        return "[Any]"
      }
      let elementType = elements.first?.typeName ?? "Any"
      return "[\(elementType)]"
    case .dictionary(let elements):
      if elements.isEmpty {
        // TODO: Consider more specific type inference for empty dictionaries
        return "[Any: Any]"
      }
      let keyType = elements.first?.0.typeName ?? "Any"
      let valueType = elements.first?.1.typeName ?? "Any"
      return "[\(keyType): \(valueType)]"
    }
  }

  /// The SwiftSyntax representation of this literal.
  public var syntax: SyntaxProtocol {
    switch self {
    case .string(let value):
      return StringLiteralExprSyntax(
        openingQuote: .stringQuoteToken(),
        segments: .init([
          .stringSegment(.init(content: .stringSegment(value)))
        ]),
        closingQuote: .stringQuoteToken()
      )
    case .float(let value):
      return FloatLiteralExprSyntax(literal: .floatLiteral(String(value)))

    case .integer(let value):
      return IntegerLiteralExprSyntax(digits: .integerLiteral(String(value)))
    case .nil:
      return NilLiteralExprSyntax(nilKeyword: .keyword(.nil))
    case .boolean(let value):
      return BooleanLiteralExprSyntax(literal: value ? .keyword(.true) : .keyword(.false))
    case .ref(let value):
      return DeclReferenceExprSyntax(baseName: .identifier(value))
    case .tuple(let elements):
      let tupleElements = TupleExprElementListSyntax(
        elements.enumerated().map { index, element in
          let elementExpr: ExprSyntax
          if let element = element {
            elementExpr =
              element.syntax.as(ExprSyntax.self)
              ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
          } else {
            // Wildcard pattern - use underscore
            elementExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("_")))
          }
          return TupleExprElementSyntax(
            label: nil,
            colon: nil,
            expression: elementExpr,
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
          )
        }
      )
      return TupleExprSyntax(
        leftParen: .leftParenToken(),
        elements: tupleElements,
        rightParen: .rightParenToken()
      )
    case .array(let elements):
      let arrayElements = ArrayElementListSyntax(
        elements.enumerated().map { index, element in
          ArrayElementSyntax(
            expression: element.syntax.as(ExprSyntax.self)
              ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(""))),
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
          )
        }
      )
      return ArrayExprSyntax(elements: arrayElements)
    case .dictionary(let elements):
      if elements.isEmpty {
        // Empty dictionary should generate [:]
        return DictionaryExprSyntax(
          leftSquare: .leftSquareToken(),
          content: .colon(.colonToken(leadingTrivia: .init(), trailingTrivia: .init())),
          rightSquare: .rightSquareToken()
        )
      } else {
        let dictionaryElements = DictionaryElementListSyntax(
          elements.enumerated().map { index, keyValue in
            let (key, value) = keyValue
            return DictionaryElementSyntax(
              keyExpression: key.syntax.as(ExprSyntax.self)
                ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(""))),
              colon: .colonToken(),
              valueExpression: value.syntax.as(ExprSyntax.self)
                ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(""))),
              trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
            )
          }
        )
        return DictionaryExprSyntax(content: .elements(dictionaryElements))
      }
    }
  }
}
