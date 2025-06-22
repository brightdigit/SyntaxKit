//
//  ParameterExpBuilderResult.swift
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

/// A result builder for creating arrays of ``ParameterExp``s.
@resultBuilder
public enum ParameterExpBuilderResult {
  /// Builds a block of ``ParameterExp``s.
  public static func buildBlock(_ components: ParameterExp...) -> [ParameterExp] {
    components
  }

  /// Builds an optional ``ParameterExp``.
  public static func buildOptional(_ component: ParameterExp?) -> [ParameterExp] {
    component.map { [$0] } ?? []
  }

  /// Builds a ``ParameterExp`` from an `if` statement.
  public static func buildEither(first: ParameterExp) -> [ParameterExp] {
    [first]
  }

  /// Builds a ``ParameterExp`` from an `else` statement.
  public static func buildEither(second: ParameterExp) -> [ParameterExp] {
    [second]
  }

  /// Builds an array of ``ParameterExp``s from a `for` loop.
  public static func buildArray(_ components: [ParameterExp]) -> [ParameterExp] {
    components
  }
}
