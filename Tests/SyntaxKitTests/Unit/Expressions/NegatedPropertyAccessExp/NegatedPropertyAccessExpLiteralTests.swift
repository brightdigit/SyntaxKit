//
//  NegatedPropertyAccessExpLiteralTests.swift
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

import Foundation
import SwiftSyntax
import Testing

@testable import SyntaxKit

/// Test suite for literal/collection NegatedPropertyAccessExp expression functionality.
internal final class NegatedPropertyAccessExpLiteralTests {
  /// Tests negated property access with literal base.
  @Test("Negated property access with literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("constant"),
        propertyName: "isValid"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!constant.isValid"))
  }

  /// Tests negated property access with array literal base.
  @Test("Negated property access with array literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithArrayLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("array"),
        propertyName: "isEmpty"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!array.isEmpty"))
  }

  /// Tests negated property access with dictionary literal base.
  @Test("Negated property access with dictionary literal base generates correct syntax")
  internal func testNegatedPropertyAccessWithDictionaryLiteralBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("dict"),
        propertyName: "isEmpty"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!dict.isEmpty"))
  }
}
