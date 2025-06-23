//
//  WeakReferenceExp.swift
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

/// A Swift weak reference expression (e.g., `weak self`).
public struct WeakReferenceExp: CodeBlock {
  private let base: CodeBlock
  private let referenceType: String

  /// Creates a weak reference expression.
  /// - Parameters:
  ///   - base: The base expression to reference.
  ///   - referenceType: The type of reference (e.g., "weak", "unowned").
  public init(base: CodeBlock, referenceType: String) {
    self.base = base
    self.referenceType = referenceType
  }

  public var syntax: SyntaxProtocol {
    // For capture lists, we need to create a proper weak reference
    // This will be handled by the Closure syntax when used in capture lists
    let baseExpr = ExprSyntax(
      fromProtocol: base.syntax.as(ExprSyntax.self)
        ?? DeclReferenceExprSyntax(baseName: .identifier(""))
    )

    // Create a custom expression that represents a weak reference
    // This will be used by the Closure to create proper capture syntax
    return baseExpr
  }

  /// Returns the reference type for use in capture lists
  internal var captureSpecifier: String {
    referenceType
  }

  /// Returns the base expression for use in capture lists
  internal var captureExpression: CodeBlock {
    base
  }
}
