//
//  Literal+Convenience.swift
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

// MARK: - Convenience Methods

extension Literal {
  /// Creates a tuple literal from an array of optional literals (for patterns with wildcards).
  public static func tuplePattern(_ elements: [Literal?]) -> Literal {
    .tuple(elements)
  }

  /// Creates an integer literal.
  public static func int(_ value: Int) -> Literal {
    .integer(value)
  }

  /// Converts a Literal.tuple to a TupleLiteral for use in Variable declarations.
  public var asTupleLiteral: (any CodeBlockableLiteral)? {
    switch self {
    case .tuple(let elements):
      return TupleLiteralArray(elements)
    default:
      return nil
    }
  }
}
