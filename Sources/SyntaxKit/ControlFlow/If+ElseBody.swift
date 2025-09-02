//
//  If+ElseBody.swift
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

extension If {
  /// Builds the else body for the if expression.
  /// - Returns: The else body syntax or nil if no else body exists.
  public func buildElseBody() -> IfExprSyntax.ElseBody? {
    guard let elseBlocks = elseBody else {
      return nil
    }

    // Build a chained else-if structure if the builder provided If blocks.
    var current: SyntaxProtocol?

    for block in elseBlocks.reversed() {
      current = processElseBlock(block, current: current)
    }

    return createElseBody(from: current)
  }

  /// Processes a single else block and updates the current syntax.
  private func processElseBlock(
    _ block: CodeBlock,
    current: SyntaxProtocol?
  ) -> SyntaxProtocol? {
    switch block {
    case let thenBlock as Then:
      return buildThenBlock(thenBlock)
    case let ifBlock as If:
      return processIfBlock(ifBlock, current: current)
    default:
      return buildDefaultElseBlock(block)
    }
  }

  /// Builds a Then block for the else clause.
  private func buildThenBlock(_ thenBlock: Then) -> SyntaxProtocol {
    let stmts = CodeBlockItemListSyntax(
      thenBlock.body.compactMap { element in
        createCodeBlockItem(from: element)?.with(\.trailingTrivia, .newline)
      }
    )
    return CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: stmts,
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    ) as SyntaxProtocol
  }

  /// Creates an else choice from a syntax protocol.
  private func createElseChoice(from nested: SyntaxProtocol) -> IfExprSyntax.ElseBody {
    if let codeBlock = nested.as(CodeBlockSyntax.self) {
      return IfExprSyntax.ElseBody(codeBlock)
    } else if let nestedIf = nested.as(IfExprSyntax.self) {
      return IfExprSyntax.ElseBody(nestedIf)
    } else {
      // Fallback to empty code block
      #warning(
        "TODO: Review fallback to empty code block - consider if this should be an error instead")
      return IfExprSyntax.ElseBody(
        CodeBlockSyntax(
          leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
          statements: CodeBlockItemListSyntax([]),
          rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
      )
    }
  }

  /// Processes an If block to build the else-if chain.
  private func processIfBlock(
    _ ifBlock: If,
    current: SyntaxProtocol?
  ) -> SyntaxProtocol? {
    guard var ifExpr = ifBlock.syntax.as(IfExprSyntax.self) else {
      return current
    }

    if let nested = current {
      let elseChoice = createElseChoice(from: nested)
      ifExpr =
        ifExpr
        .with(\.elseKeyword, .keyword(.else, leadingTrivia: .space, trailingTrivia: .space))
        .with(\.elseBody, elseChoice)
    }
    return ifExpr as SyntaxProtocol
  }

  /// Builds a default else block for any other CodeBlock type.
  private func buildDefaultElseBlock(_ block: CodeBlock) -> SyntaxProtocol? {
    guard let item = createCodeBlockItem(from: block) else {
      return nil
    }

    return CodeBlockSyntax(
      leftBrace: .leftBraceToken(
        leadingTrivia: .space,
        trailingTrivia: .newline
      ),
      statements: CodeBlockItemListSyntax([item.with(\.trailingTrivia, .newline)]),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )
  }

  /// Creates the final else body from the processed syntax.
  private func createElseBody(from current: SyntaxProtocol?) -> IfExprSyntax.ElseBody? {
    guard let final = current else {
      return nil
    }

    if let codeBlock = final.as(CodeBlockSyntax.self) {
      return IfExprSyntax.ElseBody(codeBlock)
    } else if let ifExpr = final.as(IfExprSyntax.self) {
      return IfExprSyntax.ElseBody(ifExpr)
    }
    return nil
  }
}
