//
//  OptionalChainingBasicTests.swift
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

/// Test suite for basic OptionalChainingExp expression functionality.
///
/// This test suite covers the basic optional chaining expression functionality
/// (e.g., `self?`, `user?`) in SyntaxKit.
internal final class OptionalChainingBasicTests {
  /// Tests basic optional chaining expression.
  @Test("Basic optional chaining expression generates correct syntax")
  internal func testBasicOptionalChaining() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("user")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("user?"))
  }

  /// Tests optional chaining with function call.
  @Test("Optional chaining with function call generates correct syntax")
  internal func testOptionalChainingWithFunctionCall() {
    let optionalChain = OptionalChainingExp(
      base: Call("getUser")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("getUser()?"))
  }

  /// Tests optional chaining with complex expression.
  @Test("Optional chaining with complex expression generates correct syntax")
  internal func testOptionalChainingWithComplexExpression() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(
        base: Call("getUserManager"),
        propertyName: "currentUser"
      )
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser?"))
  }

  /// Tests optional chaining with method call.
  @Test("Optional chaining with method call generates correct syntax")
  internal func testOptionalChainingWithMethodCall() {
    let optionalChain = OptionalChainingExp(
      base: Call("getUser")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("getUser()?"))
  }

  /// Tests optional chaining with complex nested structure.
  @Test("Optional chaining with complex nested structure generates correct syntax")
  internal func testOptionalChainingWithComplexNestedStructure() {
    let complexExpr = PropertyAccessExp(
      base: Call("getUserManager"),
      propertyName: "currentUser"
    )
    let optionalChain = OptionalChainingExp(base: complexExpr)

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("getUserManager().currentUser?"))
  }

  /// Tests optional chaining with multiple levels.
  @Test("Optional chaining with multiple levels generates correct syntax")
  internal func testOptionalChainingWithMultipleLevels() {
    let level1 = OptionalChainingExp(base: VariableExp("user"))
    let level2 = OptionalChainingExp(
      base: PropertyAccessExp(base: level1, propertyName: "profile")
    )
    let level3 = OptionalChainingExp(
      base: PropertyAccessExp(base: level2, propertyName: "settings")
    )

    let syntax = level3.syntax
    let description = syntax.description

    #expect(description.contains("user?.profile?.settings?"))
  }

  /// Tests optional chaining with conditional expression.
  @Test("Optional chaining with conditional expression generates correct syntax")
  internal func testOptionalChainingWithConditionalExpression() {
    let conditional = ConditionalOp(
      if: VariableExp("isEnabled"),
      then: VariableExp("user"),
      else: VariableExp("guest")
    )

    let optionalChain = OptionalChainingExp(base: conditional)

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("isEnabled ? user : guest?"))
  }

  /// Tests optional chaining with closure expression.
  @Test("Optional chaining with closure expression generates correct syntax")
  internal func testOptionalChainingWithClosureExpression() {
    let optionalChain = OptionalChainingExp(
      base: Closure(body: { VariableExp("result") })
    )

    let syntax = optionalChain.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("{ result }?".normalize()))
  }

  /// Tests optional chaining with parenthesized expression.
  @Test("Optional chaining with parenthesized expression generates correct syntax")
  internal func testOptionalChainingWithParenthesizedExpression() {
    let optionalChain = OptionalChainingExp(
      base: Parenthesized { VariableExp("expression") }
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("(expression)?"))
  }
}
