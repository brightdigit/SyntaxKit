//
//  CodeBlockBuilderResult.swift
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

/// A result builder for creating arrays of ``CodeBlock``s.
@resultBuilder
public enum CodeBlockBuilderResult: Sendable {
  /// Builds an empty block of ``CodeBlock``s.
  public static func buildBlock() -> [CodeBlock] {
    []
  }

  /// Builds a block of ``CodeBlock``s.
  public static func buildBlock(_ components: CodeBlock...) -> [CodeBlock] {
    components
  }

  /// Builds an optional ``CodeBlock``.
  public static func buildOptional(_ component: CodeBlock?) -> CodeBlock {
    component ?? EmptyCodeBlock()
  }

  /// Builds a ``CodeBlock`` from an `if` statement.
  public static func buildEither(first: CodeBlock) -> CodeBlock {
    first
  }

  /// Builds a ``CodeBlock`` from an `else` statement.
  public static func buildEither(second: CodeBlock) -> CodeBlock {
    second
  }

  /// Builds an array of ``CodeBlock``s from a `for` loop.
  public static func buildArray(_ components: [CodeBlock]) -> [CodeBlock] {
    components
  }

  public static func buildBlock(_ components: [CodeBlock]...) -> [CodeBlock] {
    components.flatMap { $0 }
  }

  /// Builds an array of ``CodeBlock``s from a `for` loop.
  public static func buildArray(_ components: [[CodeBlock]]) -> [CodeBlock] {
    components.flatMap { $0 }
  }
}
