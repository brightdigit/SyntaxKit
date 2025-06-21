//
//  Do.swift
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

/// A Swift `do` statement for error handling.
public struct Do: CodeBlock {
  private let body: [CodeBlock]
  private let catchClauses: CatchClauseListSyntax

  /// Creates a `do-catch` statement.
  /// - Parameters:
  ///   - body: A ``CodeBlockBuilder`` that provides the body of the do block.
  ///   - catchClauses: A ``CatchBuilder`` that provides the catch clauses.
  public init(
    @CodeBlockBuilderResult _ body: () -> [CodeBlock],
    @CatchBuilder catch catchClauses: () -> CatchClauseListSyntax
  ) {
    self.body = body()
    self.catchClauses = catchClauses()
  }

  public var syntax: SyntaxProtocol {
    // Build the do body
    let doBody = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
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
        }),
      rightBrace: .rightBraceToken(leadingTrivia: .newline, trailingTrivia: .space)
    )

    return StmtSyntax(
      DoStmtSyntax(
        doKeyword: .keyword(.do, trailingTrivia: .space),
        body: doBody,
        catchClauses: catchClauses
      )
    )
  }
}
