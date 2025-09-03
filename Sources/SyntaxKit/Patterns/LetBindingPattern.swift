//
//  LetBindingPattern.swift
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

// MARK: - Let binding pattern

/// Namespace for pattern creation utilities.
public enum Pattern {
  /// Creates a `let` binding pattern for switch cases.
  /// - Parameter identifier: The name of the variable to bind.
  /// - Returns: A pattern that binds the value to the given identifier.
  public static func `let`(_ identifier: String) -> any PatternConvertible {
    LetBindingPattern(identifier: identifier)
  }
}

/// A `let` binding pattern for switch cases.
internal struct LetBindingPattern: PatternConvertible {
  private let identifier: String

  /// SwiftSyntax representation of the let binding pattern.
  internal var patternSyntax: PatternSyntax {
    PatternSyntax(
      ValueBindingPatternSyntax(
        bindingSpecifier: .keyword(.let, trailingTrivia: .space),
        pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(identifier)))
      )
    )
  }

  internal init(identifier: String) {
    self.identifier = identifier
  }
}
