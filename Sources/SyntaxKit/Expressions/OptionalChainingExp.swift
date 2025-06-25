//
//  OptionalChainingExp.swift
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

/// A Swift optional chaining expression (e.g., `self?`).
public struct OptionalChainingExp: CodeBlock {
  private let base: CodeBlock

  /// Creates an optional chaining expression.
  /// - Parameter base: The base expression to make optional.
  public init(base: CodeBlock) {
    self.base = base
  }

  public var syntax: SyntaxProtocol {
    // Convert base.syntax to ExprSyntax more safely
    let baseExpr: ExprSyntax
    if let exprSyntax = base.syntax.as(ExprSyntax.self) {
      baseExpr = exprSyntax
    } else {
      // Fallback to a default expression if conversion fails
      #warning(
        "TODO: Review fallback for failed expression conversion"
      )
      baseExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
    }

    // Add optional chaining operator
    return PostfixOperatorExprSyntax(
      expression: baseExpr,
      operator: .postfixOperator("?", trailingTrivia: [])
    )
  }
}
