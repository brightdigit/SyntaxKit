//
//  VariableDecl.swift
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

/// A Swift `let` or `var` declaration.
@available(*, deprecated, message: "Use Variable instead for more features and flexibility")
public struct VariableDecl: CodeBlock {
  private let kind: VariableKind
  private let name: String
  private let value: String?

  /// Creates a `let` or `var` declaration.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - value: The initial value of the variable, if any.
  public init(_ kind: VariableKind, name: String, equals value: String? = nil) {
    self.kind = kind
    self.name = name
    self.value = value
  }

  public var syntax: SyntaxProtocol {
    let bindingKeyword = TokenSyntax.keyword(kind == .let ? .let : .var, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name, trailingTrivia: .space)
    let initializer = value.map { value in
      if value.hasPrefix("\"") && value.hasSuffix("\"") {
        return InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: StringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: StringLiteralSegmentListSyntax([
              .stringSegment(
                StringSegmentSyntax(content: .stringSegment(String(value.dropFirst().dropLast())))
              )
            ]),
            closingQuote: .stringQuoteToken()
          )
        )
      } else if value.contains("\\(") {
        return InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: StringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: StringLiteralSegmentListSyntax([
              .stringSegment(
                StringSegmentSyntax(content: .stringSegment(value))
              )
            ]),
            closingQuote: .stringQuoteToken()
          )
        )
      } else {
        return InitializerClauseSyntax(
          equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
          value: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(value)))
        )
      }
    }
    return VariableDeclSyntax(
      bindingSpecifier: bindingKeyword,
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: identifier),
          typeAnnotation: nil,
          initializer: initializer
        )
      ])
    )
  }
}
