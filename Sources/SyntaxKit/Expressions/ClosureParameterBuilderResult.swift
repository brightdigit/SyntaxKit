//
//  ClosureParameterBuilderResult.swift
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

@resultBuilder
public struct ClosureParameterBuilderResult {
  /// Builds a block of closure parameters.
  /// - Parameter components: The closure parameters to combine.
  /// - Returns: An array of closure parameters.
  public static func buildBlock(_ components: ClosureParameter...) -> [ClosureParameter] {
    components
  }

  /// Builds an optional closure parameter.
  /// - Parameter component: The optional closure parameter.
  /// - Returns: An array containing the parameter if present, otherwise empty.
  public static func buildOptional(_ component: ClosureParameter?) -> [ClosureParameter] {
    component.map { [$0] } ?? []
  }

  /// Builds the first branch of an either expression.
  /// - Parameter component: The closure parameter from the first branch.
  /// - Returns: An array containing the parameter.
  public static func buildEither(first component: ClosureParameter) -> [ClosureParameter] {
    [component]
  }

  /// Builds the second branch of an either expression.
  /// - Parameter component: The closure parameter from the second branch.
  /// - Returns: An array containing the parameter.
  public static func buildEither(second component: ClosureParameter) -> [ClosureParameter] {
    [component]
  }

  /// Builds an array of closure parameters.
  /// - Parameter components: The arrays of closure parameters to flatten.
  /// - Returns: A flattened array of closure parameters.
  public static func buildArray(_ components: [ClosureParameter]) -> [ClosureParameter] {
    components
  }
}
