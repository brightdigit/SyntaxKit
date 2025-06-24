//
//  CodeBlock+ExprSyntax.swift
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

extension CodeBlock {
  /// Attempts to treat this `CodeBlock` as an expression and return its `ExprSyntax` form.
  ///
  /// If the underlying syntax already *is* an `ExprSyntax`, it is returned directly. If the
  /// underlying syntax is a bare `TokenSyntax` (commonly the case for `VariableExp` which
  /// produces an identifier token), we wrap it in a `DeclReferenceExprSyntax` so that it becomes
  /// a valid expression node. For any other kind of syntax, we create a default empty expression
  /// to prevent crashes while still allowing code generation to continue.
  public var expr: ExprSyntax {
    if let expr = self.syntax.as(ExprSyntax.self) {
      return expr
    }

    if let token = self.syntax.as(TokenSyntax.self) {
      return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(token.text)))
    }

    // Fallback for unsupported syntax types - create a default expression
    // This prevents crashes while still allowing code generation to continue
    return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
  }
}
