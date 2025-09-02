//
//  PatternConvertibleBuilder.swift
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

/// A result builder for creating pattern-convertible types.
@resultBuilder
public enum PatternConvertibleBuilder: Sendable, Equatable {
  /// Builds a single pattern convertible code block from the provided pattern.
  /// - Parameter pattern: The pattern convertible code block to build.
  /// - Returns: The pattern convertible code block unchanged.
  public static func buildBlock(_ pattern: any CodeBlock & PatternConvertible) -> any CodeBlock
    & PatternConvertible
  {
    pattern
  }

  /// Builds a pattern convertible code block from a single pattern.
  /// - Parameter pattern: The pattern convertible code block to build.
  /// - Returns: The pattern convertible code block unchanged.
  public static func buildExpression(_ pattern: any CodeBlock & PatternConvertible) -> any CodeBlock
    & PatternConvertible
  {
    pattern
  }

  /// Builds a pattern convertible code block from the first branch of a conditional.
  /// - Parameter first: The pattern convertible code block from the first branch.
  /// - Returns: The pattern convertible code block from the first branch.
  public static func buildEither(first: any CodeBlock & PatternConvertible) -> any CodeBlock
    & PatternConvertible
  {
    first
  }

  /// Builds a pattern convertible code block from the second branch of a conditional.
  /// - Parameter second: The pattern convertible code block from the second branch.
  /// - Returns: The pattern convertible code block from the second branch.
  public static func buildEither(second: any CodeBlock & PatternConvertible) -> any CodeBlock
    & PatternConvertible
  {
    second
  }
}
