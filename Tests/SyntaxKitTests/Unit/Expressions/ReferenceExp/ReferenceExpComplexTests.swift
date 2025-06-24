//
//  ReferenceExpComplexTests.swift
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

/// Test suite for ReferenceExp complex expression functionality.
///
/// This test suite covers the reference expression functionality
/// with complex expressions in SyntaxKit.
internal final class ReferenceExpComplexTests {
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
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("isEnabled ? enabledValue : disabledValue"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with closure base.
  @Test("Reference expression with closure base generates correct syntax")
  internal func testReferenceWithClosureBase() {
    let closure = Closure(body: { VariableExp("result") })
    let reference = ReferenceExp(
      base: closure,
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("{ result }".normalize()))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with enum case base.
  @Test("Reference expression with enum case base generates correct syntax")
  internal func testReferenceWithEnumCaseBase() {
    let enumCase = EnumCase("active")
    let reference = ReferenceExp(
      base: enumCase,
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description.normalize()

    #expect(description.contains(".active".normalize()))
    #expect(reference.captureReferenceType == .weak)
  }
}
