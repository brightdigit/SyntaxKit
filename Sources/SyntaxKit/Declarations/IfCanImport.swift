//
//  IfCanImport.swift
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

/// A `#if canImport(Module)` … `#endif` conditional compilation block.
public struct IfCanImport: CodeBlock, Sendable {
  private let moduleName: String
  private let content: [any CodeBlock]

  /// The SwiftSyntax representation of this conditional compilation block.
  public var syntax: any SyntaxProtocol {
    let canImportRef = DeclReferenceExprSyntax(baseName: .identifier("canImport"))
    let moduleRef = DeclReferenceExprSyntax(baseName: .identifier(moduleName))
    let condition = FunctionCallExprSyntax(
      calledExpression: ExprSyntax(canImportRef),
      leftParen: .leftParenToken(),
      arguments: LabeledExprListSyntax([
        LabeledExprSyntax(expression: ExprSyntax(moduleRef))
      ]),
      rightParen: .rightParenToken()
    )

    let items = CodeBlockItemListSyntax(
      content.compactMap { block -> CodeBlockItemSyntax? in
        CodeBlockItemSyntax.Item.create(from: block.syntax).map {
          CodeBlockItemSyntax(item: $0, trailingTrivia: .newline)
        }
      }
    )

    let clause = IfConfigClauseSyntax(
      poundKeyword: .poundIfToken(trailingTrivia: .space),
      condition: ExprSyntax(condition).with(\.trailingTrivia, .newline),
      elements: .statements(items)
    )

    return IfConfigDeclSyntax(
      clauses: IfConfigClauseListSyntax([clause]),
      poundEndif: .poundEndifToken(leadingTrivia: .newline)
    )
  }

  /// Creates a `#if canImport(moduleName)` block wrapping the given content.
  /// - Parameters:
  ///   - moduleName: The module name passed to `canImport`.
  ///   - content: The code blocks to emit when the module is available.
  public init(_ moduleName: String, @CodeBlockBuilderResult _ content: () -> [any CodeBlock]) {
    self.moduleName = moduleName
    self.content = content()
  }
}
