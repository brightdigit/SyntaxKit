//
//  InitializerDecl.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

/// A Swift `init` declaration.
public struct InitializerDecl: CodeBlock, Sendable {
  private let body: [any CodeBlock]
  private var accessModifier: AccessModifier?
  private var isAsync: Bool = false
  private var isThrowing: Bool = false

  /// The SwiftSyntax representation of this initializer declaration.
  public var syntax: any SyntaxProtocol {
    var modifiers: DeclModifierListSyntax = []
    if let access = accessModifier {
      modifiers = DeclModifierListSyntax([
        DeclModifierSyntax(name: .keyword(access.keyword, trailingTrivia: .space))
      ])
    }

    var effectSpecifiers: FunctionEffectSpecifiersSyntax?
    if isAsync || isThrowing {
      effectSpecifiers = FunctionEffectSpecifiersSyntax(
        asyncSpecifier: isAsync
          ? .keyword(.async, leadingTrivia: .space, trailingTrivia: .space)
          : nil,
        throwsSpecifier: isThrowing ? .keyword(.throws, leadingTrivia: .space) : nil
      )
    }

    let bodyBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap { item in
          var codeBlockItem: CodeBlockItemSyntax?
          if let decl = item.syntax.as(DeclSyntax.self) {
            codeBlockItem = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = item.syntax.as(ExprSyntax.self) {
            codeBlockItem = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = item.syntax.as(StmtSyntax.self) {
            codeBlockItem = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return codeBlockItem?.with(\.trailingTrivia, .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    return InitializerDeclSyntax(
      modifiers: modifiers,
      initKeyword: .keyword(.`init`),
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax(
          leftParen: .leftParenToken(),
          parameters: FunctionParameterListSyntax([]),
          rightParen: .rightParenToken()
        ),
        effectSpecifiers: effectSpecifiers
      ),
      body: bodyBlock
    )
  }

  /// Creates an `init` declaration.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the initializer.
  public init(@CodeBlockBuilderResult _ content: () throws -> [any CodeBlock]) rethrows {
    self.body = try content()
  }

  /// Sets the access modifier for the initializer declaration.
  /// - Parameter access: The access modifier.
  /// - Returns: A copy of the initializer with the access modifier set.
  public func access(_ access: AccessModifier) -> Self {
    var copy = self
    copy.accessModifier = access
    return copy
  }

  /// Marks the initializer as `throws`.
  /// - Returns: A copy of the initializer marked as `throws`.
  public func throwing() -> Self {
    var copy = self
    copy.isThrowing = true
    return copy
  }

  /// Marks the initializer as `async`.
  /// - Returns: A copy of the initializer marked as `async`.
  public func async() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }
}
