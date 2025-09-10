//
//  ReferenceExpBasicTests.swift
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

/// Test suite for basic ReferenceExp expression functionality.
///
/// This test suite covers the basic reference expression functionality
/// (e.g., `weak self`, `unowned self`) in SyntaxKit.
internal final class ReferenceExpBasicTests {
  /// Tests basic weak reference expression.
  @Test("Basic weak reference expression generates correct syntax")
  internal func testBasicWeakReference() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests basic unowned reference expression.
  @Test("Basic unowned reference expression generates correct syntax")
  internal func testBasicUnownedReference() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: .unowned
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("self"))
    #expect(reference.captureReferenceType == .unowned)
  }

  /// Tests reference expression with variable base.
  @Test("Reference expression with variable base generates correct syntax")
  internal func testReferenceWithVariableBase() {
    let reference = ReferenceExp(
      base: VariableExp("delegate"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("delegate"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with different reference types.
  @Test("Reference expression with different reference types generates correct syntax")
  internal func testReferenceWithDifferentReferenceTypes() {
    let weakRef = ReferenceExp(base: VariableExp("self"), referenceType: .weak)
    let unownedRef = ReferenceExp(base: VariableExp("self"), referenceType: .unowned)

    #expect(weakRef.captureReferenceType == .weak)
    #expect(unownedRef.captureReferenceType == .unowned)
  }

  /// Tests capture expression property access.
  @Test("Capture expression property access returns correct base")
  internal func testCaptureExpressionPropertyAccess() {
    let base = VariableExp("self")
    let reference = ReferenceExp(
      base: base,
      referenceType: .weak
    )

    #expect(reference.captureExpression.syntax.description == base.syntax.description)
  }

  /// Tests capture reference type property access.
  @Test("Capture reference type property access returns correct type")
  internal func testCaptureReferenceTypePropertyAccess() {
    let reference = ReferenceExp(
      base: VariableExp("self"),
      referenceType: .unowned
    )

    #expect(reference.captureReferenceType == .unowned)
  }
}
