//
//  Variable.swift
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

import Foundation
import SwiftSyntax

/// A Swift `let` or `var` declaration with an explicit type.
public struct Variable: CodeBlock {
  private let kind: VariableKind
  private let name: String
  private let type: String
  private let defaultValue: CodeBlock?
  private var isStatic: Bool = false
  private var isAsync: Bool = false
  private var attributes: [AttributeInfo] = []
  private var explicitType: Bool = false

  /// Internal initializer used by extension initializers to reduce code duplication.
  /// - Parameters:
  ///   - kind: The kind of variable, either ``VariableKind/let`` or ``VariableKind/var``.
  ///   - name: The name of the variable.
  ///   - type: The type of the variable. If nil, will be inferred from defaultValue if it's an Init.
  ///   - defaultValue: The initial value expression of the variable, if any.
  ///   - explicitType: Whether the variable has an explicit type.
  internal init(
    kind: VariableKind,
    name: String,
    type: String? = nil,
    defaultValue: CodeBlock? = nil,
    explicitType: Bool = false
  ) {
    self.kind = kind
    self.name = name

    // If type is provided, use it; otherwise try to infer from defaultValue
    if let providedType = type {
      self.type = providedType
    } else if let initValue = defaultValue as? Init {
      self.type = initValue.typeName
    } else {
      self.type = ""
    }

    self.defaultValue = defaultValue
    self.explicitType = explicitType
  }

  /// Marks the variable as `static`.
  /// - Returns: A copy of the variable marked as `static`.
  public func `static`() -> Self {
    var copy = self
    copy.isStatic = true
    return copy
  }

  /// Marks the variable as `async`.
  /// - Returns: A copy of the variable marked as `async`.
  public func async() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }

  /// Adds an attribute to the variable declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the variable with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public func withExplicitType() -> Self {
    var copy = self
    copy.explicitType = true
    return copy
  }

  public var syntax: SyntaxProtocol {
    let bindingKeyword = TokenSyntax.keyword(kind == .let ? .let : .var, trailingTrivia: .space)
    let identifier = TokenSyntax.identifier(name, trailingTrivia: .space)
    let typeAnnotation: TypeAnnotationSyntax? =
      (explicitType && !type.isEmpty)
      ? TypeAnnotationSyntax(
        colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
        type: IdentifierTypeSyntax(name: .identifier(type))
      ) : nil
    let initializer = defaultValue.map { value in
      let expr: ExprSyntax
      if let exprBlock = value as? ExprCodeBlock {
        expr = exprBlock.exprSyntax
      } else if let exprSyntax = value.syntax.as(ExprSyntax.self) {
        expr = exprSyntax
      } else {
        expr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
      }
      return InitializerClauseSyntax(
        equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
        value: expr
      )
    }
    var modifiers: DeclModifierListSyntax = []
    if isStatic {
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(.static, trailingTrivia: .space))
      ])
    }
    if isAsync {
      modifiers = DeclModifierListSyntax(
        modifiers + [
          DeclModifierSyntax(name: .keyword(.async, trailingTrivia: .space))
        ]
      )
    }
    return VariableDeclSyntax(
      attributes: buildAttributeList(from: attributes),
      modifiers: modifiers,
      bindingSpecifier: bindingKeyword,
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: identifier),
          typeAnnotation: typeAnnotation,
          initializer: initializer
        )
      ])
    )
  }

  private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
    if attributes.isEmpty {
      return AttributeListSyntax([])
    }

    let attributeElements = attributes.map { attributeInfo in
      let arguments = attributeInfo.arguments

      var leftParen: TokenSyntax?
      var rightParen: TokenSyntax?
      var argumentsSyntax: AttributeSyntax.Arguments?

      if !arguments.isEmpty {
        leftParen = .leftParenToken()
        rightParen = .rightParenToken()

        let argumentList = arguments.map { argument in
          DeclReferenceExprSyntax(baseName: .identifier(argument))
        }

        argumentsSyntax = .argumentList(
          LabeledExprListSyntax(
            argumentList.enumerated().map { index, expr in
              var element = LabeledExprSyntax(expression: ExprSyntax(expr))
              if index < argumentList.count - 1 {
                element = element.with(\.trailingComma, .commaToken(trailingTrivia: .space))
              }
              return element
            }
          )
        )
      }

      return AttributeListSyntax.Element(
        AttributeSyntax(
          atSign: .atSignToken(),
          attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
          leftParen: leftParen,
          arguments: argumentsSyntax,
          rightParen: rightParen
        )
      )
    }

    return AttributeListSyntax(attributeElements)
  }

  public enum VariableKind {
    case `var`
    case `let`
    case `static`
    case `lazy`
    case `weak`
    case `unowned`
    case `final`
    case `override`
    case `mutating`
  }
}
