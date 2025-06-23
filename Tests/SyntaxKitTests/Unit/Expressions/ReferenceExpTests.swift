//
//  ReferenceExpTests.swift
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

/// Test suite for ReferenceExp expression functionality.
///
/// This test suite covers the reference expression functionality
/// (e.g., `weak self`, `unowned self`) in SyntaxKit.
internal final class ReferenceExpTests {
  /// Tests basic weak reference expression.
  @Test("Basic weak reference expression generates correct syntax")
  internal func testBasicWeakReference() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests basic unowned reference expression.
  @Test("Basic unowned reference expression generates correct syntax")
  internal func testBasicUnownedReference() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: "unowned"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == "unowned")
  }

  /// Tests reference expression with variable base.
  @Test("Reference expression with variable base generates correct syntax")
  internal func testReferenceWithVariableBase() {
    let reference = ReferenceExp(
      base: VariableExp("delegate"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("delegate"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with property access base.
  @Test("Reference expression with property access base generates correct syntax")
  internal func testReferenceWithPropertyAccessBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(base: VariableExp("viewController"), propertyName: "delegate"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("viewController.delegate"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with function call base.
  @Test("Reference expression with function call base generates correct syntax")
  internal func testReferenceWithFunctionCallBase() {
    let reference = ReferenceExp(
      base: Call("getCurrentUser"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getCurrentUser()"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with complex base expression.
  @Test("Reference expression with complex base expression generates correct syntax")
  internal func testReferenceWithComplexBaseExpression() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      ),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with different reference types.
  @Test("Reference expression with different reference types generates correct syntax")
  internal func testReferenceWithDifferentReferenceTypes() {
    let weakRef = ReferenceExp(base: VariableExp("self"), referenceType: "weak")
    let unownedRef = ReferenceExp(base: VariableExp("self"), referenceType: "unowned")
    let strongRef = ReferenceExp(base: VariableExp("self"), referenceType: "strong")

    #expect(weakRef.captureReferenceType == "weak")
    #expect(unownedRef.captureReferenceType == "unowned")
    #expect(strongRef.captureReferenceType == "strong")
  }

  /// Tests reference expression with literal base.
  @Test("Reference expression with literal base generates correct syntax")
  internal func testReferenceWithLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.ref("constant"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("constant"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with array literal base.
  @Test("Reference expression with array literal base generates correct syntax")
  internal func testReferenceWithArrayLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.array([Literal.string("item1"), Literal.string("item2")]),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("[\"item1\", \"item2\"]"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with dictionary literal base.
  @Test("Reference expression with dictionary literal base generates correct syntax")
  internal func testReferenceWithDictionaryLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.dictionary([(Literal.string("key"), Literal.string("value"))]),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description.replacingOccurrences(of: " ", with: "")

    #expect(description.contains("[\"key\":\"value\"]".replacingOccurrences(of: " ", with: "")))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with tuple literal base.
  @Test("Reference expression with tuple literal base generates correct syntax")
  internal func testReferenceWithTupleLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.tuple([Literal.string("first"), Literal.string("second")]),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("(\"first\", \"second\")"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with conditional operator base.
  @Test("Reference expression with conditional operator base generates correct syntax")
  internal func testReferenceWithConditionalOperatorBase() {
    let conditional = ConditionalOp(
      if: VariableExp("isEnabled"),
      then: VariableExp("enabledValue"),
      else: VariableExp("disabledValue")
    )

    let reference = ReferenceExp(
      base: conditional,
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("isEnabled ? enabledValue : disabledValue"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with closure base.
  @Test("Reference expression with closure base generates correct syntax")
  internal func testReferenceWithClosureBase() {
    let closure = Closure(body: { VariableExp("result") })
    let reference = ReferenceExp(
      base: closure,
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("{ result }".normalize()))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with enum case base.
  @Test("Reference expression with enum case base generates correct syntax")
  internal func testReferenceWithEnumCaseBase() {
    let enumCase = EnumCase("active")
    let reference = ReferenceExp(
      base: enumCase,
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description.normalize()

    #expect(description.contains(".active".normalize()))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with init call base.
  @Test("Reference expression with init call base generates correct syntax")
  internal func testReferenceWithInitCallBase() {
    let initCall = Init("String")
    let reference = ReferenceExp(
      base: initCall,
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("String()"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with nested property access base.
  @Test("Reference expression with nested property access base generates correct syntax")
  internal func testReferenceWithNestedPropertyAccessBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile"),
        propertyName: "settings"
      ),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("user.profile.settings"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with method call base.
  @Test("Reference expression with method call base generates correct syntax")
  internal func testReferenceWithMethodCallBase() {
    let reference = ReferenceExp(
      base: Call("getData"),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getData()"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests reference expression with complex nested expression base.
  @Test("Reference expression with complex nested expression base generates correct syntax")
  internal func testReferenceWithComplexNestedExpressionBase() {
    let reference = ReferenceExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      ),
      referenceType: "weak"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser"))
    #expect(reference.captureReferenceType == "weak")
  }

  /// Tests capture expression property access.
  @Test("Capture expression property access returns correct base")
  internal func testCaptureExpressionPropertyAccess() {
    let base = VariableExp("self")
    let reference = ReferenceExp(
      base: base,
      referenceType: "weak"
    )

    #expect(reference.captureExpression.syntax.description == base.syntax.description)
  }

  /// Tests capture reference type property access.
  @Test("Capture reference type property access returns correct type")
  internal func testCaptureReferenceTypePropertyAccess() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: "unowned"
    )

    #expect(reference.captureReferenceType == "unowned")
  }

  /// Tests reference expression with empty string reference type.
  @Test("Reference expression with empty string reference type generates correct syntax")
  internal func testReferenceWithEmptyStringReferenceType() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: ""
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == "")
  }

  /// Tests reference expression with custom reference type.
  @Test("Reference expression with custom reference type generates correct syntax")
  internal func testReferenceWithCustomReferenceType() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: "custom"
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == "custom")
  }
}
