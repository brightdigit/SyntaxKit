//
//  NegatedPropertyAccessExpBasicTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax
import Testing

@testable import SyntaxKit

/// Test suite for basic NegatedPropertyAccessExp expression functionality.
///
/// This test suite covers the basic negated property access expression
/// functionality (e.g., `!user.isEnabled`) in SyntaxKit.
internal final class NegatedPropertyAccessExpBasicTests {
  /// Tests basic negated property access expression.
  @Test("Basic negated property access expression generates correct syntax")
  internal func testBasicNegatedPropertyAccess() {
    let negatedAccess = NegatedPropertyAccessExp(
      baseName: "user",
      propertyName: "isEnabled"
    )

    let syntax = negatedAccess.syntax
    let description = syntax.description

    #expect(description.contains("!user.isEnabled"))
  }
}
