//
//  EnumCase.swift
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

/// A Swift `case` declaration inside an `enum`.
public struct EnumCase: CodeBlock {
  private let name: String
  private var literalValue: Literal?
  private var associatedValues: [(name: String, type: String)] = []

  /// The name of the enum case.
  public var caseName: String { name }

  /// The associated values for the enum case, if any.
  public var caseAssociatedValues: [(name: String, type: String)] { associatedValues }

  /// Creates a `case` declaration.
  /// - Parameter name: The name of the case.
  public init(_ name: String) {
    self.name = name
    self.literalValue = nil
  }

  /// Sets the associated value for the case.
  /// - Parameters:
  ///   - name: The name of the associated value.
  ///   - type: The type of the associated value.
  /// - Returns: A copy of the case with the associated value set.
  public func associatedValue(_ name: String, type: String) -> Self {
    var copy = self
    copy.associatedValues.append((name: name, type: type))
    return copy
  }

  /// Sets the raw value of the case to a Literal.
  /// - Parameter value: The literal value.
  /// - Returns: A copy of the case with the raw value set.
  public func equals(_ value: Literal) -> Self {
    var copy = self
    copy.literalValue = value
    return copy
  }

  /// Sets the raw value of the case to a string (for backward compatibility).
  /// - Parameter value: The string value.
  /// - Returns: A copy of the case with the raw value set.
  public func equals(_ value: String) -> Self {
    self.equals(.string(value))
  }

  /// Sets the raw value of the case to an integer (for backward compatibility).
  /// - Parameter value: The integer value.
  /// - Returns: A copy of the case with the raw value set.
  public func equals(_ value: Int) -> Self {
    self.equals(.integer(value))
  }

  /// Sets the raw value of the case to a float (for backward compatibility).
  /// - Parameter value: The float value.
  /// - Returns: A copy of the case with the raw value set.
  public func equals(_ value: Double) -> Self {
    self.equals(.float(value))
  }

  /// Returns a SwiftSyntax expression for this enum case (for use in throw/return/etc).
  public var asExpressionSyntax: ExprSyntax {
    let parts = name.split(separator: ".", maxSplits: 1)
    let base: ExprSyntax? =
      parts.count == 2
      ? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(String(parts[0]))))
      : nil
    let caseName = parts.count == 2 ? String(parts[1]) : name
    let memberAccess = MemberAccessExprSyntax(
      base: base,
      dot: .periodToken(),
      name: .identifier(caseName)
    )
    if !associatedValues.isEmpty {
      let tuple = TupleExprSyntax(
        leftParen: .leftParenToken(),
        elements: TupleExprElementListSyntax(
          associatedValues.map { associated in
            TupleExprElementSyntax(
              label: nil,
              colon: nil,
              expression: ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier(associated.name))),
              trailingComma: nil
            )
          }
        ),
        rightParen: .rightParenToken()
      )
      return ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: ExprSyntax(memberAccess),
          leftParen: tuple.leftParen,
          arguments: tuple.elements,
          rightParen: tuple.rightParen
        ))
    } else {
      return ExprSyntax(memberAccess)
    }
  }

  /// Returns the expression syntax for this enum case.
  /// This is the preferred method when using EnumCase in expression contexts.
  public var exprSyntax: ExprSyntax {
    asExpressionSyntax
  }

  /// Returns the appropriate syntax based on context.
  /// When used in expressions (throw, return, if bodies), returns expression syntax.
  /// When used in declarations (enum cases), returns declaration syntax.
  public var syntax: SyntaxProtocol {
    // Check if we're in an expression context by looking at the call stack
    // For now, we'll use a heuristic: if this is being used in a context that expects expressions,
    // we'll return the expression syntax. Otherwise, we'll return the declaration syntax.

    // Since we can't easily determine context from here, we'll provide both options
    // and let the calling code choose. For now, we'll default to declaration syntax
    // and let specific contexts (like Throw) handle the conversion.

    let caseKeyword = TokenSyntax.keyword(.case, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name, trailingTrivia: .space)

    var parameterClause: EnumCaseParameterClauseSyntax?
    if !associatedValues.isEmpty {
      let parameters = EnumCaseParameterListSyntax(
        associatedValues.map { associated in
          EnumCaseParameterSyntax(
            firstName: .identifier(associated.name),
            secondName: .identifier(associated.name),
            colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(associated.type)))
          )
        }
      )
      parameterClause = EnumCaseParameterClauseSyntax(
        leftParen: .leftParenToken(),
        parameters: parameters,
        rightParen: .rightParenToken()
      )
    }

    var initializer: InitializerClauseSyntax?
    if let literal = literalValue {
      switch literal {
      case .string(let value):
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: StringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: StringLiteralSegmentListSyntax([
              .stringSegment(StringSegmentSyntax(content: .stringSegment(value)))
            ]),
            closingQuote: .stringQuoteToken()
          )
        )
      case .float(let value):
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: FloatLiteralExprSyntax(literal: .floatLiteral(String(value)))
        )
      case .integer(let value):
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: IntegerLiteralExprSyntax(digits: .integerLiteral(String(value)))
        )
      case .nil:
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: NilLiteralExprSyntax(nilKeyword: .keyword(.nil))
        )
      case .boolean(let value):
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: BooleanLiteralExprSyntax(literal: value ? .keyword(.true) : .keyword(.false))
        )
      case .ref(let value):
        initializer = InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: DeclReferenceExprSyntax(baseName: .identifier(value))
        )
      case .tuple:
        fatalError("Tuple is not supported as a raw value for enum cases.")
      case .array:
        fatalError("Array is not supported as a raw value for enum cases.")
      case .dictionary:
        fatalError("Dictionary is not supported as a raw value for enum cases.")
      }
    }

    return EnumCaseDeclSyntax(
      caseKeyword: caseKeyword,
      elements: EnumCaseElementListSyntax([
        EnumCaseElementSyntax(
          leadingTrivia: .space,
          _: nil,
          name: identifier,
          _: nil,
          parameterClause: parameterClause,
          _: nil,
          rawValue: initializer,
          _: nil,
          trailingComma: nil,
          trailingTrivia: .newline
        )
      ])
    )
  }
}
