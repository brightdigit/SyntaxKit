//
//  PoundIf.TargetEnvironmentCheck.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

extension PoundIf {
  /// `targetEnvironment(<TargetEnvironment>)`
  public struct TargetEnvironmentCheck: LeafCondition {
    /// The target environment being checked.
    public let value: TargetEnvironment
    /// The `targetEnvironment` keyword.
    public var keyword: String? { "targetEnvironment" }
    /// The environment identifier rendered inside the parentheses.
    public var argument: String { value.rawValue }
  }
}

extension PoundIf.Condition where Self == PoundIf.TargetEnvironmentCheck {
  /// `targetEnvironment(<TargetEnvironment>)`
  /// - Parameter value: The target environment to test for.
  /// - Returns: A `targetEnvironment` condition.
  public static func targetEnvironment(
    _ value: PoundIf.TargetEnvironment
  ) -> PoundIf.TargetEnvironmentCheck {
    .init(value: value)
  }
}
