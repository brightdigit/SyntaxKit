//
//  ExprCodeBlockBuilder.swift
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

/// A result builder that produces exactly one `ExprCodeBlock`.
/// This ensures compile-time type safety for expression-based constructs.
@resultBuilder
public struct ExprCodeBlockBuilder {
  public static func buildBlock(_ expression: any ExprCodeBlock) -> any ExprCodeBlock {
    expression
  }

  public static func buildExpression(_ expression: any ExprCodeBlock) -> any ExprCodeBlock {
    expression
  }

  public static func buildEither(first: any ExprCodeBlock) -> any ExprCodeBlock {
    first
  }

  public static func buildEither(second: any ExprCodeBlock) -> any ExprCodeBlock {
    second
  }

  public static func buildOptional(_ expression: (any ExprCodeBlock)?) -> any ExprCodeBlock {
    // This should never be called in practice since we require exactly one expression
    fatalError("ExprCodeBlockBuilder requires exactly one expression")
  }

  public static func buildArray(_ expressions: [any ExprCodeBlock]) -> any ExprCodeBlock {
    // This should never be called in practice since we require exactly one expression
    fatalError("ExprCodeBlockBuilder requires exactly one expression")
  }
}
