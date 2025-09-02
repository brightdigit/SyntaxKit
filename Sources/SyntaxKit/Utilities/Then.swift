//
//  Then.swift
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

/// A helper that represents the *final* `else` body in an `if` / `else-if` chain.
///
/// In the DSL this lets users write:
/// ```swift
/// If { condition } then: { ... } else: {
///   If { otherCond } then: { ... }
///   Then {             // <- final else
///     Call("print", "fallback")
///   }
/// }
/// ```
/// so that the builder can distinguish a nested `If` (for `else if`) from the
/// *terminal* `else` body.
public struct Then: CodeBlock {
  /// The statements that make up the `else` body.
  public let body: [CodeBlock]

  /// Creates a then block.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the then block.
  public init(@CodeBlockBuilderResult _ content: () throws -> [CodeBlock]) rethrows {
    self.body = try content()
  }

  public var syntax: SyntaxProtocol {
    let statements = CodeBlockItemListSyntax(
      body.compactMap { element in
        if let decl = element.syntax.as(DeclSyntax.self) {
          return CodeBlockItemSyntax(item: .decl(decl)).with(\.trailingTrivia, .newline)
        } else if let expr = element.syntax.as(ExprSyntax.self) {
          return CodeBlockItemSyntax(item: .expr(expr)).with(\.trailingTrivia, .newline)
        } else if let stmt = element.syntax.as(StmtSyntax.self) {
          return CodeBlockItemSyntax(item: .stmt(stmt)).with(\.trailingTrivia, .newline)
        }
        return nil
      }
    )

    return CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: statements,
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )
  }
}
