//
//  ComputedProperty.swift
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

/// A Swift `var` declaration with a computed value.
public struct ComputedProperty: CodeBlock {
  private let name: String
  private let type: String
  private let body: [CodeBlock]
  private var accessModifier: String?
  private let explicitType: Bool

  /// Creates a computed property declaration.
  /// - Parameters:
  ///   - name: The name of the property.
  ///   - type: The type of the property.
  ///   - explicitType: Whether the type should be explicitly marked.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the getter.
  public init(
    _ name: String, type: String, explicitType: Bool = true,
    @CodeBlockBuilderResult _ content: () -> [CodeBlock]
  ) {
    self.name = name
    self.type = type
    self.explicitType = explicitType
    self.body = content()
  }

  /// Sets the access modifier for the computed property declaration.
  /// - Parameter access: The access modifier (e.g., "public", "private").
  /// - Returns: A copy of the computed property with the access modifier set.
  public func access(_ access: String) -> Self {
    var copy = self
    copy.accessModifier = access
    return copy
  }

  public var syntax: SyntaxProtocol {
    let accessor = AccessorBlockSyntax(
      leftBrace: TokenSyntax.leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      accessors: .getter(
        CodeBlockItemListSyntax(
          body.compactMap {
            var item: CodeBlockItemSyntax?
            if let decl = $0.syntax.as(DeclSyntax.self) {
              item = CodeBlockItemSyntax(item: .decl(decl))
            } else if let expr = $0.syntax.as(ExprSyntax.self) {
              item = CodeBlockItemSyntax(item: .expr(expr))
            } else if let stmt = $0.syntax.as(StmtSyntax.self) {
              item = CodeBlockItemSyntax(item: .stmt(stmt))
            }
            return item?.with(\.trailingTrivia, .newline)
          }
        )
      ),
      rightBrace: TokenSyntax.rightBraceToken(leadingTrivia: .newline)
    )
    let identifier = TokenSyntax.identifier(
      name, trailingTrivia: explicitType ? (.space + .space) : .space)
    let typeAnnotation = TypeAnnotationSyntax(
      colon: TokenSyntax.colonToken(trailingTrivia: .space),
      type: IdentifierTypeSyntax(name: .identifier(type))
    )

    // Build modifiers
    var modifiers: DeclModifierListSyntax = []
    if let access = accessModifier {
      let keyword: Keyword
      switch access {
      case "public":
        keyword = .public
      case "private":
        keyword = .private
      case "internal":
        keyword = .internal
      case "fileprivate":
        keyword = .fileprivate
      default:
        keyword = .public  // fallback
      }
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(keyword, trailingTrivia: .space))
      ])
    }

    return VariableDeclSyntax(
      modifiers: modifiers,
      bindingSpecifier: TokenSyntax.keyword(.var, trailingTrivia: .space),
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: identifier),
          typeAnnotation: typeAnnotation,
          accessorBlock: accessor
        )
      ])
    )
  }
}
