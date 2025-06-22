//
//  CodeBlock+Generate.swift
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

extension CodeBlock {
  /// Generates the Swift code for the ``CodeBlock``.
  /// - Returns: The generated Swift code as a string.
  public func generateCode() -> String {
    let statements: CodeBlockItemListSyntax
    if let list = self.syntax.as(CodeBlockItemListSyntax.self) {
      statements = list
    } else if let codeBlock = self.syntax.as(CodeBlockSyntax.self) {
      // Handle CodeBlockSyntax by extracting its statements
      statements = codeBlock.statements
    } else {
      let item: CodeBlockItemSyntax.Item
      if let decl = self.syntax.as(DeclSyntax.self) {
        item = .decl(decl)
      } else if let stmt = self.syntax.as(StmtSyntax.self) {
        item = .stmt(stmt)
      } else if let expr = self.syntax.as(ExprSyntax.self) {
        item = .expr(expr)
      } else if let token = self.syntax.as(TokenSyntax.self) {
        // Wrap TokenSyntax in DeclReferenceExprSyntax and then in ExprSyntax
        let expr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(token.text)))
        item = .expr(expr)
      } else if let switchCase = self.syntax.as(SwitchCaseSyntax.self) {
        // Wrap SwitchCaseSyntax in a SwitchExprSyntax and treat it as an expression
        // This is a fallback for when SwitchCase is used standalone
        let switchExpr = SwitchExprSyntax(
          switchKeyword: .keyword(.switch, trailingTrivia: .space),
          subject: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("_"))),
          leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
          cases: SwitchCaseListSyntax([SwitchCaseListSyntax.Element(switchCase)]),
          rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
        item = .expr(ExprSyntax(switchExpr))
      } else {
        fatalError(
          "Unsupported syntax type at top level: \(type(of: self.syntax)) (\(self.syntax)) generating from \(self)"
        )
      }
      statements = CodeBlockItemListSyntax([
        CodeBlockItemSyntax(item: item, trailingTrivia: .newline)
      ])
    }

    let sourceFile = SourceFileSyntax(statements: statements)
    return sourceFile.description.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
