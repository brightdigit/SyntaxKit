//
//  ConditionalOpBasicTests.swift
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

/// Test suite for basic ConditionalOp expression functionality.
///
/// This test suite covers the basic ternary conditional operator expression
/// (`condition ? then : else`) functionality in SyntaxKit.
internal final class ConditionalOpBasicTests {
  /// Tests basic conditional operator with simple expressions.
  @Test("Basic conditional operator generates correct syntax")
  internal func testBasicConditionalOp() {
    let conditional = ConditionalOp(
      if: VariableExp("isEnabled"),
      then: VariableExp("true"),
      else: VariableExp("false")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isEnabled ? true : false"))
  }

  /// Tests conditional operator with complex expressions.
  @Test("Conditional operator with complex expressions generates correct syntax")
  internal func testConditionalOpWithComplexExpressions() {
    let conditional = ConditionalOp(
      if: VariableExp("user.isLoggedIn"),
      then: Call("getUserProfile"),
      else: Call("getDefaultProfile")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("user.isLoggedIn ? getUserProfile() : getDefaultProfile()"))
  }

  /// Tests conditional operator with enum cases.
  @Test("Conditional operator with enum cases generates correct syntax")
  internal func testConditionalOpWithEnumCases() {
    let conditional = ConditionalOp(
      if: VariableExp("status"),
      then: EnumCase("active"),
      else: EnumCase("inactive")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("status ? .active : .inactive"))
  }

  /// Tests conditional operator with mixed enum cases and expressions.
  @Test("Conditional operator with mixed enum cases and expressions generates correct syntax")
  internal func testConditionalOpWithMixedEnumCasesAndExpressions() {
    let conditional = ConditionalOp(
      if: VariableExp("isActive"),
      then: EnumCase("active"),
      else: VariableExp("defaultStatus")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isActive ? .active : defaultStatus"))
  }

  /// Tests nested conditional operators.
  @Test("Nested conditional operators generate correct syntax")
  internal func testNestedConditionalOperators() {
    let innerConditional = ConditionalOp(
      if: VariableExp("isPremium"),
      then: VariableExp("premiumValue"),
      else: VariableExp("standardValue")
    )

    let outerConditional = ConditionalOp(
      if: VariableExp("isEnabled"),
      then: innerConditional,
      else: VariableExp("disabledValue")
    )

    let syntax = outerConditional.syntax
    let description = syntax.description

    #expect(
      description.contains("isEnabled ? isPremium ? premiumValue : standardValue : disabledValue"))
  }

  /// Tests conditional operator with complex nested structures.
  @Test("Conditional operator with complex nested structures generates correct syntax")
  internal func testConditionalOpWithComplexNestedStructures() {
    let conditional = ConditionalOp(
      if: Call("isAuthenticated"),
      then: Call("getUserData"),
      else: Call("getGuestData")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isAuthenticated() ? getUserData() : getGuestData()"))
  }
}
