//
//  For.swift
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

/// A `for-in` loop statement.
public struct For: CodeBlock {
  private let pattern: any CodeBlock & PatternConvertible
  private let sequence: CodeBlock
  private let whereClause: CodeBlock?
  private let body: [CodeBlock]

  /// Creates a `for-in` loop statement.
  /// - Parameters:
  ///   - pattern: A `CodeBlock` that also conforms to `PatternConvertible` for the loop variable(s).
  ///   - sequence: A `CodeBlock` that produces the sequence to iterate over.
  ///   - whereClause: A `CodeBlockBuilder` that produces the where clause condition.
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    _ pattern: any CodeBlock & PatternConvertible,
    in sequence: CodeBlock,
    @CodeBlockBuilderResult where whereClause: () throws -> [CodeBlock],
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    self.pattern = pattern
    self.sequence = sequence
    let whereBlocks = try whereClause()
    self.whereClause = whereBlocks.isEmpty ? nil : whereBlocks[0]
    self.body = try then()
  }

  /// Creates a `for-in` loop statement without a where clause.
  /// - Parameters:
  ///   - pattern: A `CodeBlock` that also conforms to `PatternConvertible` for the loop variable(s).
  ///   - sequence: A `CodeBlock` that produces the sequence to iterate over.
  ///   - then: A ``CodeBlockBuilder`` that provides the body of the loop.
  public init(
    _ pattern: any CodeBlock & PatternConvertible,
    in sequence: CodeBlock,
    @CodeBlockBuilderResult then: () throws -> [CodeBlock]
  ) rethrows {
    try self.init(
      pattern,
      in: sequence,
      where: [CodeBlock].init,
      then: then
    )
  }

  public var syntax: SyntaxProtocol {
    // Build the pattern using the PatternConvertible protocol
    let patternSyntax = pattern.patternSyntax

    // Build the sequence expression
    let sequenceExpr = ExprSyntax(
      fromProtocol: sequence.syntax.as(ExprSyntax.self)
        ?? DeclReferenceExprSyntax(baseName: .identifier(""))
    )

    // Build the where clause if present
    var whereClauseSyntax: WhereClauseSyntax?
    if let whereBlock = whereClause {
      let whereExpr = ExprSyntax(
        fromProtocol: whereBlock.syntax.as(ExprSyntax.self)
          ?? DeclReferenceExprSyntax(baseName: .identifier(""))
      )
      whereClauseSyntax = WhereClauseSyntax(
        whereKeyword: .keyword(.where, leadingTrivia: .space, trailingTrivia: .space),
        guardResult: whereExpr
      )
    }

    // Build the body
    let bodyBlock = CodeBlockSyntax(
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
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    return StmtSyntax(
      ForInStmtSyntax(
        forKeyword: .keyword(.for, trailingTrivia: .space),
        tryKeyword: nil,
        awaitKeyword: nil,
        caseKeyword: nil,
        pattern: patternSyntax,
        typeAnnotation: nil,
        inKeyword: .keyword(.in, leadingTrivia: .space, trailingTrivia: .space),
        sequence: sequenceExpr,
        whereClause: whereClauseSyntax,
        body: bodyBlock
      )
    )
  }
}
