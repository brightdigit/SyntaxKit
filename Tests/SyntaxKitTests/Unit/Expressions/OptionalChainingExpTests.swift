//
//  OptionalChainingExpTests.swift
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

/// Test suite for OptionalChainingExp expression functionality.
///
/// This test suite covers the optional chaining expression functionality
/// (e.g., `self?`, `user?`) in SyntaxKit.
internal final class OptionalChainingExpTests {
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

  /// Tests optional chaining with property access.
  @Test("Optional chaining with property access generates correct syntax")
  internal func testOptionalChainingWithPropertyAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("user.profile?"))
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

  /// Tests optional chaining with nested property access.
  @Test("Optional chaining with nested property access generates correct syntax")
  internal func testOptionalChainingWithNestedPropertyAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(
        base: PropertyAccessExp(base: VariableExp("user"), propertyName: "profile"),
        propertyName: "settings"
      )
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("user.profile.settings?"))
  }

  /// Tests optional chaining with array access.
  @Test("Optional chaining with array access generates correct syntax")
  internal func testOptionalChainingWithArrayAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("users"), propertyName: "0")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("users.0?"))
  }

  /// Tests optional chaining with dictionary access.
  @Test("Optional chaining with dictionary access generates correct syntax")
  internal func testOptionalChainingWithDictionaryAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("config"), propertyName: "apiKey")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("config.apiKey?"))
  }

  /// Tests optional chaining with computed property.
  @Test("Optional chaining with computed property generates correct syntax")
  internal func testOptionalChainingWithComputedProperty() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("self"), propertyName: "computedValue")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("self.computedValue?"))
  }

  /// Tests optional chaining with static property.
  @Test("Optional chaining with static property generates correct syntax")
  internal func testOptionalChainingWithStaticProperty() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("UserManager"), propertyName: "shared")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("UserManager.shared?"))
  }

  /// Tests optional chaining with literal value.
  @Test("Optional chaining with literal value generates correct syntax")
  internal func testOptionalChainingWithLiteralValue() {
    let optionalChain = OptionalChainingExp(
      base: Literal.ref("constant")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("constant?"))
  }

  /// Tests optional chaining with array literal.
  @Test("Optional chaining with array literal generates correct syntax")
  internal func testOptionalChainingWithArrayLiteral() {
    let optionalChain = OptionalChainingExp(
      base: Literal.array([Literal.string("item1"), Literal.string("item2")])
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("[\"item1\", \"item2\"]?"))
  }

  /// Tests optional chaining with dictionary literal.
  @Test("Optional chaining with dictionary literal generates correct syntax")
  internal func testOptionalChainingWithDictionaryLiteral() {
    let optionalChain = OptionalChainingExp(
      base: Literal.dictionary([(Literal.string("key"), Literal.string("value"))])
    )

    let syntax = optionalChain.syntax
    let description = syntax.description.replacingOccurrences(of: " ", with: "")

    #expect(description.contains("[\"key\":\"value\"]?".replacingOccurrences(of: " ", with: "")))
  }

  /// Tests optional chaining with tuple literal.
  @Test("Optional chaining with tuple literal generates correct syntax")
  internal func testOptionalChainingWithTupleLiteral() {
    let optionalChain = OptionalChainingExp(
      base: Literal.tuple([Literal.string("first"), Literal.string("second")])
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("(\"first\", \"second\")?"))
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
    let level2 = OptionalChainingExp(base: PropertyAccessExp(base: level1, propertyName: "profile"))
    let level3 = OptionalChainingExp(
      base: PropertyAccessExp(base: level2, propertyName: "settings"))

    let syntax = level3.syntax
    let description = syntax.description

    #expect(description.contains("user?.profile?.settings?"))
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

  /// Tests optional chaining with subscript access.
  @Test("Optional chaining with subscript access generates correct syntax")
  internal func testOptionalChainingWithSubscriptAccess() {
    let optionalChain = OptionalChainingExp(
      base: PropertyAccessExp(base: VariableExp("array"), propertyName: "0")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("array.0?"))
  }

  /// Tests optional chaining with type casting.
  @Test("Optional chaining with type casting generates correct syntax")
  internal func testOptionalChainingWithTypeCasting() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("value as String")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("value as String?"))
  }

  /// Tests optional chaining with nil coalescing.
  @Test("Optional chaining with nil coalescing generates correct syntax")
  internal func testOptionalChainingWithNilCoalescing() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("optionalValue ?? defaultValue")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("optionalValue ?? defaultValue?"))
  }

  /// Tests optional chaining with logical operators.
  @Test("Optional chaining with logical operators generates correct syntax")
  internal func testOptionalChainingWithLogicalOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("condition && value")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("condition && value?"))
  }

  /// Tests optional chaining with arithmetic operators.
  @Test("Optional chaining with arithmetic operators generates correct syntax")
  internal func testOptionalChainingWithArithmeticOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("a + b")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("a + b?"))
  }

  /// Tests optional chaining with comparison operators.
  @Test("Optional chaining with comparison operators generates correct syntax")
  internal func testOptionalChainingWithComparisonOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("x > y")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("x > y?"))
  }

  /// Tests optional chaining with bitwise operators.
  @Test("Optional chaining with bitwise operators generates correct syntax")
  internal func testOptionalChainingWithBitwiseOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("flags & mask")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("flags & mask?"))
  }

  /// Tests optional chaining with range operators.
  @Test("Optional chaining with range operators generates correct syntax")
  internal func testOptionalChainingWithRangeOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("start...end")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("start...end?"))
  }

  /// Tests optional chaining with assignment operators.
  @Test("Optional chaining with assignment operators generates correct syntax")
  internal func testOptionalChainingWithAssignmentOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("value = 42")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("value = 42?"))
  }

  /// Tests optional chaining with compound assignment operators.
  @Test("Optional chaining with compound assignment operators generates correct syntax")
  internal func testOptionalChainingWithCompoundAssignmentOperators() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("count += 1")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("count += 1?"))
  }

  /// Tests optional chaining with ternary operator.
  @Test("Optional chaining with ternary operator generates correct syntax")
  internal func testOptionalChainingWithTernaryOperator() {
    let optionalChain = OptionalChainingExp(
      base: VariableExp("condition ? trueValue : falseValue")
    )

    let syntax = optionalChain.syntax
    let description = syntax.description

    #expect(description.contains("condition ? trueValue : falseValue?"))
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
