//
//  NegatedPropertyAccessExpFunctionTests.swift
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

/// Test suite for function/method call NegatedPropertyAccessExp expression functionality.
internal final class NegatedPropertyAccessExpFunctionTests {
  /// Tests negated property access with method call.
  @Test("Negated property access with method call generates correct syntax")
  internal func testNegatedPropertyAccessWithMethodCall() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getData"),
        propertyName: "isValid"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!getData().isValid"))
  }

  /// Tests negated property access with function call base.
  @Test("Negated property access with function call base generates correct syntax")
  internal func testNegatedPropertyAccessWithFunctionCallBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getCurrentUser"),
        propertyName: "isActive"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!getCurrentUser().isActive"))
  }

  /// Tests negated property access with complex function call base.
  @Test("Negated property access with complex function call base generates correct syntax")
  internal func testNegatedPropertyAccessWithComplexFunctionCallBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "isAuthenticated"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!getUserManager().isAuthenticated"))
  }
}
