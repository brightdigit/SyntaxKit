//
//  CodeBlockItemSyntax.Item.swift
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

extension CodeBlockItemSyntax.Item {
  /// Creates a `CodeBlockItemSyntax.Item` from a `SyntaxProtocol`.
  /// - Parameter syntax: The syntax to convert.
  /// - Returns: A `CodeBlockItemSyntax.Item` if the conversion is successful, `nil` otherwise.
  public static func create(from syntax: any SyntaxProtocol) -> CodeBlockItemSyntax.Item? {
    if let decl = syntax.as(DeclSyntax.self) {
      return .decl(decl)
    } else if let stmt = syntax.as(StmtSyntax.self) {
      return .stmt(stmt)
    } else if let expr = syntax.as(ExprSyntax.self) {
      return .expr(expr)
    } else if let token = syntax.as(TokenSyntax.self) {
      // Wrap TokenSyntax in DeclReferenceExprSyntax and then in ExprSyntax
      let expr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(token.text)))
      return .expr(expr)
    } else if let switchCase = syntax.as(SwitchCaseSyntax.self) {
      // Wrap SwitchCaseSyntax in a SwitchExprSyntax and treat it as an expression
      // This is a fallback for when SwitchCase is used standalone
      #warning(
        "TODO: Review fallback for SwitchCase used standalone - consider if this should be an error instead"
      )
      let switchExpr = SwitchExprSyntax(
        switchKeyword: .keyword(.switch, trailingTrivia: .space),
        subject: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("_"))),
        leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
        cases: SwitchCaseListSyntax([SwitchCaseListSyntax.Element(switchCase)]),
        rightBrace: .rightBraceToken(leadingTrivia: .newline)
      )
      return .expr(ExprSyntax(switchExpr))
    } else {
      return nil
    }
  }
}
