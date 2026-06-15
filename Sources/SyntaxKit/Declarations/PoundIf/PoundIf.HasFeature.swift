//
//  PoundIf.HasFeature.swift
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
  /// `hasFeature(<name>)`
  public struct HasFeature: LeafCondition {
    /// The upcoming/experimental feature name.
    public let name: String
    /// The `hasFeature` keyword.
    public var keyword: String? { "hasFeature" }
    /// The feature name rendered inside the parentheses.
    public var argument: String { name }
  }
}

extension PoundIf.Condition where Self == PoundIf.HasFeature {
  /// `hasFeature(<name>)`
  /// - Parameter name: The feature name to test for.
  /// - Returns: A `hasFeature` condition.
  public static func hasFeature(_ name: String) -> PoundIf.HasFeature {
    .init(name: name)
  }
}
