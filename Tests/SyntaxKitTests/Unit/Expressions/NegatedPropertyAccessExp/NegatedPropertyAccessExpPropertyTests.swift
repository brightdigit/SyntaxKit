//
//  NegatedPropertyAccessExpPropertyTests.swift
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

/// Test suite for property access NegatedPropertyAccessExp expression functionality.
internal final class NegatedPropertyAccessExpPropertyTests {
  /// Tests negated property access with complex base expression.
  @Test("Negated property access with complex base expression generates correct syntax")
  internal func testNegatedPropertyAccessWithComplexBaseExpression() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!getUserManager().currentUser"))
  }

  /// Tests negated property access with deeply nested property access.
  @Test("Negated property access with deeply nested property access generates correct syntax")
  internal func testNegatedPropertyAccessWithDeeplyNestedPropertyAccess() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(
          base: PropertyAccessExp(
            base: Call("getUserManager"),
            propertyName: "currentUser"
          ),
          propertyName: "profile"
        ),
        propertyName: "settings"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!getUserManager().currentUser.profile.settings"))
  }

  /// Tests negated property access with nested property access base.
  @Test("Negated property access with nested property access base generates correct syntax")
  internal func testNegatedPropertyAccessWithNestedPropertyAccessBase() {
    let negatedAccess = NegatedPropertyAccessExp(
      base: PropertyAccessExp(
        base: VariableExp("viewController"),
        propertyName: "delegate"
      )
    )
    let syntax = negatedAccess.syntax
    let description = syntax.description
    #expect(description.contains("!viewController.delegate"))
  }
}
