//
//  ReferenceExpPropertyTests.swift
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

/// Test suite for ReferenceExp property access functionality.
///
/// This test suite covers the reference expression functionality
/// with property access in SyntaxKit.
internal final class ReferenceExpPropertyTests {
  /// Tests reference expression with property access base.
  @Test("Reference expression with property access base generates correct syntax")
  internal func testReferenceWithPropertyAccessBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(base: VariableExp("viewController"), propertyName: "delegate"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("viewController.delegate"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with nested property access base.
  @Test("Reference expression with nested property access base generates correct syntax")
  internal func testReferenceWithNestedPropertyAccessBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile"),
        propertyName: "settings"
      ),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("user.profile.settings"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with complex base expression.
  @Test("Reference expression with complex base expression generates correct syntax")
  internal func testReferenceWithComplexBaseExpression() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      ),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with complex nested expression base.
  @Test("Reference expression with complex nested expression base generates correct syntax")
  internal func testReferenceWithComplexNestedExpressionBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      ),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser"))
    #expect(reference.captureReferenceType == .weak)
  }
}
