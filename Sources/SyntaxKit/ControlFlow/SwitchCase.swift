//
//  SwitchCase.swift
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

/// A `case` in a `switch` statement.
public struct SwitchCase: CodeBlock {
  private let patterns: [PatternConvertible]
  private let body: [CodeBlock]

  /// Creates a `case` for a `switch` statement.
  /// - Parameters:
  ///   - patterns: The patterns to match for the case. Must conform to `PatternConvertible`.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the case.
  public init(
    _ patterns: PatternConvertible..., @CodeBlockBuilderResult content: () throws -> [CodeBlock]
  )
    rethrows
  {
    self.patterns = patterns
    self.body = try content()
  }

  /// Creates a `case` for a `switch` statement with a builder closure for the conditional.
  /// - Parameters:
  ///   - conditional: A ``CodeBlockBuilder`` that provides the conditional patterns for the case.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the case.
  public init(
    @CodeBlockBuilderResult conditional: () throws -> [PatternConvertible],
    @CodeBlockBuilderResult content: () throws -> [CodeBlock]
  ) rethrows {
    self.patterns = try conditional()
    self.body = try content()
  }

  public var switchCaseSyntax: SwitchCaseSyntax {
    let caseItems = SwitchCaseItemListSyntax(
      patterns.enumerated().compactMap { index, pattern -> SwitchCaseItemSyntax? in
        let patternSyntax = pattern.patternSyntax

        var item = SwitchCaseItemSyntax(pattern: patternSyntax)
        if index < patterns.count - 1 {
          item = item.with(
            \.trailingComma,
            .commaToken(trailingTrivia: .space)
          )
        }
        return item
      }
    )

    // Handle special case for multiple conditionals with let binding and where clause
    var finalCaseItems = caseItems
    if patterns.count >= 2 {
      // Check if we have a let binding followed by an expression (where clause)
      if let firstPattern = patterns.first as? SwitchLet,
        let secondPattern = patterns[1] as? CodeBlock
      {
        let letIdentifier = IdentifierPatternSyntax(identifier: .identifier(firstPattern.name))
        let whereExpr = ExprSyntax(
          fromProtocol: secondPattern.syntax.as(ExprSyntax.self)
            ?? DeclReferenceExprSyntax(baseName: .identifier(""))
        )

        let valueBindingPattern = ValueBindingPatternSyntax(
          bindingSpecifier: .keyword(.let, trailingTrivia: .space),
          pattern: letIdentifier
        )

        let whereClause = WhereClauseSyntax(
          whereKeyword: .keyword(
            .where,
            leadingTrivia: .space,
            trailingTrivia: .space
          ),
          condition: whereExpr
        )

        // Create a case item with the value binding pattern and where clause
        let caseItem = SwitchCaseItemSyntax(
          pattern: PatternSyntax(valueBindingPattern),
          whereClause: whereClause
        )
        finalCaseItems = SwitchCaseItemListSyntax([caseItem])
      }
    }

    var statementItems = body.compactMap { block -> CodeBlockItemSyntax? in
      if let decl = block.syntax.as(DeclSyntax.self) {
        return CodeBlockItemSyntax(item: .decl(decl)).with(\.trailingTrivia, .newline)
      } else if let expr = block.syntax.as(ExprSyntax.self) {
        return CodeBlockItemSyntax(item: .expr(expr)).with(\.trailingTrivia, .newline)
      } else if let stmt = block.syntax.as(StmtSyntax.self) {
        return CodeBlockItemSyntax(item: .stmt(stmt)).with(\.trailingTrivia, .newline)
      }
      return nil
    }
    if statementItems.isEmpty {
      // Add a break statement if the case body is empty
      let breakStmt = BreakStmtSyntax(breakKeyword: .keyword(.break, trailingTrivia: .newline))
      statementItems = [CodeBlockItemSyntax(item: .stmt(StmtSyntax(breakStmt)))]
    }
    let statements = CodeBlockItemListSyntax(statementItems)
    let label = SwitchCaseLabelSyntax(
      caseKeyword: .keyword(.case, trailingTrivia: .space),
      caseItems: finalCaseItems,
      colon: .colonToken(trailingTrivia: .newline)
    )
    return SwitchCaseSyntax(
      label: .case(label),
      statements: statements
    )
  }

  public var syntax: SyntaxProtocol { switchCaseSyntax }
}
