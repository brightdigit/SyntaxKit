//
//  Switch.swift
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

/// A Swift `switch` statement.
public struct Switch: CodeBlock, Sendable {
  private let expression: any CodeBlock
  private let cases: [any CodeBlock]

  public var syntax: any SyntaxProtocol {
    let expr = ExprSyntax(
      fromProtocol: expression.syntax.as(ExprSyntax.self)
        ?? DeclReferenceExprSyntax(baseName: .identifier(""))
    )
    let casesArr: [SwitchCaseSyntax] = self.cases.compactMap {
      if let tupleCase = $0 as? Case {
        return tupleCase.switchCaseSyntax
      }
      if let switchCase = $0 as? SwitchCase {
        return switchCase.switchCaseSyntax
      }
      if let switchDefault = $0 as? Default {
        return switchDefault.switchCaseSyntax
      }
      return nil
    }
    let cases = SwitchCaseListSyntax(casesArr.map { SwitchCaseListSyntax.Element($0) })
    let switchExpr = SwitchExprSyntax(
      switchKeyword: .keyword(.switch, trailingTrivia: .space),
      subject: expr,
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      cases: cases,
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )
    return switchExpr
  }

  /// Creates a `switch` statement.
  /// - Parameters:
  ///   - expression: The expression to switch on.
  ///   - content: A ``CodeBlockBuilder`` that provides the cases for the switch.
  public init(
    _ expression: any CodeBlock, @CodeBlockBuilderResult _ content: () throws -> [any CodeBlock]
  )
    rethrows
  {
    self.expression = expression
    self.cases = try content()
  }

  /// Convenience initializer that accepts a string expression.
  /// - Parameters:
  ///   - expression: The string expression to switch on.
  ///   - content: A ``CodeBlockBuilder`` that provides the cases for the switch.
  public init(_ expression: String, @CodeBlockBuilderResult _ content: () throws -> [any CodeBlock])
    rethrows
  {
    self.expression = VariableExp(expression)
    self.cases = try content()
  }
}
