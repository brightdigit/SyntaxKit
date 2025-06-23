//
//  Task.swift
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

/// A Swift Task expression for structured concurrency.
public struct Task: CodeBlock {
  private let body: [CodeBlock]
  private var attributes: [AttributeInfo] = []

  /// Creates a Task expression.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the task.
  public init(@CodeBlockBuilderResult _ content: () -> [CodeBlock]) {
    self.body = content()
  }

  /// Adds an attribute to the task.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the task with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    let bodyBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap { block in
          var item: CodeBlockItemSyntax?
          if let decl = block.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = block.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = block.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return item?.with(\.trailingTrivia, .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )

    let taskExpr = FunctionCallExprSyntax(
      calledExpression: ExprSyntax(
        DeclReferenceExprSyntax(baseName: .identifier("Task"))
      ),
      leftParen: .leftParenToken(),
      arguments: LabeledExprListSyntax([
        LabeledExprSyntax(
          label: nil,
          colon: nil,
          expression: ExprSyntax(
            ClosureExprSyntax(
              signature: nil,
              statements: bodyBlock.statements
            )
          )
        )
      ]),
      rightParen: .rightParenToken()
    )

    // Add attributes if present
    if !attributes.isEmpty {
      // For now, just return the task expression without attributes
      // since AttributedExprSyntax is not available
      return ExprSyntax(taskExpr)
    } else {
      return ExprSyntax(taskExpr)
    }
  }
}
