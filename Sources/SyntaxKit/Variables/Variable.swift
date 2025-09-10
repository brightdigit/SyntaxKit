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
public import SwiftSyntax

/// A Swift `let` or `var` declaration with an explicit type.
public struct Variable: CodeBlock {
  private let kind: VariableKind
  private let name: String
  private let type: any TypeRepresentable
  private let defaultValue: (any CodeBlock)?
  internal var isStatic: Bool = false
  internal var isAsync: Bool = false
  private var attributes: [AttributeInfo] = []
  private var explicitType: Bool = false
  internal var accessModifier: AccessModifier?

  /// The SwiftSyntax representation of this variable declaration.
  public var syntax: any SyntaxProtocol {
    let bindingKeyword = buildBindingKeyword()
    let identifier = buildIdentifier()
    let typeAnnotation = buildTypeAnnotation()
    let initializer = buildInitializer()
    let modifiers = buildModifiers()

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
    type: (any TypeRepresentable)? = nil,
    defaultValue: (any CodeBlock)? = nil,
    explicitType: Bool = false
  ) {
    self.kind = kind
    self.name = name
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

  /// Sets the access modifier for the variable declaration.
  /// - Parameter access: The access modifier.
  /// - Returns: A copy of the variable with the access modifier set.
  public func access(_ access: AccessModifier) -> Self {
    var copy = self
    copy.accessModifier = access
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

  /// Returns a copy of the variable with explicit type annotation enabled.
  /// - Returns: A new variable instance with explicit type annotation enabled.
  public func withExplicitType() -> Self {
    var copy = self
    copy.explicitType = true
    return copy
  }

  // MARK: - Private Helper Methods

  private func buildBindingKeyword() -> TokenSyntax {
    TokenSyntax.keyword(kind == .let ? .let : .var, trailingTrivia: .space)
  }

  private func buildIdentifier() -> TokenSyntax {
    TokenSyntax.identifier(
      name,
      trailingTrivia: explicitType ? (.space + .space) : .space
    )
  }

  private func buildTypeAnnotation() -> TypeAnnotationSyntax? {
    let shouldShowType = explicitType && !(type is String && (type as? String)?.isEmpty != false)
    guard shouldShowType else {
      return nil
    }

    return TypeAnnotationSyntax(
      colon: .colonToken(trailingTrivia: .space),
      type: type.typeSyntax
    )
  }

  private func buildInitializer() -> InitializerClauseSyntax? {
    guard let defaultValue = defaultValue else {
      return nil
    }

    let expr = buildExpressionFromValue(defaultValue)

    return InitializerClauseSyntax(
      equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
      value: expr
    )
  }

  private func buildExpressionFromValue(_ value: any CodeBlock) -> ExprSyntax {
    if let exprBlock = value as? any ExprCodeBlock {
      return exprBlock.exprSyntax
    } else if let exprSyntax = value.syntax.as(ExprSyntax.self) {
      return exprSyntax
    } else {
      return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
    }
  }
}
