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

public import SwiftSyntax

/// A Swift `case` declaration inside an `enum`.
public struct EnumCase: CodeBlock {
  internal let name: String
  internal var literalValue: Literal?
  internal var associatedValues: [(name: String, type: String)] = []

  /// The name of the enum case.
  public var caseName: String { name }

  /// The associated values for the enum case, if any.
  public var caseAssociatedValues: [(name: String, type: String)] { associatedValues }

  /// Returns a SwiftSyntax expression for this enum case (for use in throw/return/etc).
  public var asExpressionSyntax: ExprSyntax {
    let parts = name.split(separator: ".", maxSplits: 1)
    let hasAssociated = !associatedValues.isEmpty
    if parts.count == 1 && !hasAssociated {
      // Only a case name, no type, no associated values: generate `.caseName`
      return ExprSyntax(
        MemberAccessExprSyntax(
          base: nil as ExprSyntax?,
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: .identifier(name))
        )
      )
    }
    let base: ExprSyntax? =
      parts.count == 2
      ? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(String(parts[0]))))
      : nil
    let caseName = parts.count == 2 ? String(parts[1]) : name
    let memberAccess = MemberAccessExprSyntax(
      base: base,
      period: .periodToken(),
      declName: DeclReferenceExprSyntax(baseName: .identifier(caseName))
    )
    if hasAssociated {
      let args = LabeledExprListSyntax(
        associatedValues.enumerated().map { index, associated in
          LabeledExprSyntax(
            label: nil,
            colon: nil,
            expression: ExprSyntax(
              DeclReferenceExprSyntax(baseName: .identifier(associated.name))
            ),
            trailingComma: index < associatedValues.count - 1
              ? .commaToken(trailingTrivia: .space) : nil
          )
        }
      )
      return ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: ExprSyntax(memberAccess),
          leftParen: .leftParenToken(),
          arguments: args,
          rightParen: .rightParenToken()
        )
      )
    } else {
      return ExprSyntax(memberAccess)
    }
  }

  /// Returns the expression syntax for this enum case.
  /// This is the preferred method when using EnumCase in expression contexts.
  public var exprSyntax: ExprSyntax {
    asExpressionSyntax
  }

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
}
