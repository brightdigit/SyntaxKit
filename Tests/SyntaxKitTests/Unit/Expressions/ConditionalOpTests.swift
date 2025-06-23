//
//  ConditionalOpTests.swift
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

/// Test suite for ConditionalOp expression functionality.
///
/// This test suite covers the ternary conditional operator expression
/// (`condition ? then : else`) functionality in SyntaxKit.
internal final class ConditionalOpTests {
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

  /// Tests conditional operator with nested conditional operators.
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

  /// Tests conditional operator with function calls.
  @Test("Conditional operator with function calls generates correct syntax")
  internal func testConditionalOpWithFunctionCalls() {
    let conditional = ConditionalOp(
      if: Call("isValid"),
      then: Call("processValid"),
      else: Call("handleInvalid")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isValid() ? processValid() : handleInvalid()"))
  }

  /// Tests conditional operator with property access.
  @Test("Conditional operator with property access generates correct syntax")
  internal func testConditionalOpWithPropertyAccess() {
    let conditional = ConditionalOp(
      if: PropertyAccessExp(base: VariableExp("user"), propertyName: "isAdmin"),
      then: PropertyAccessExp(base: VariableExp("user"), propertyName: "adminSettings"),
      else: PropertyAccessExp(base: VariableExp("user"), propertyName: "defaultSettings")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("user.isAdmin ? user.adminSettings : user.defaultSettings"))
  }

  /// Tests conditional operator with literal values.
  @Test("Conditional operator with literal values generates correct syntax")
  internal func testConditionalOpWithLiteralValues() {
    let conditional = ConditionalOp(
      if: VariableExp("count"),
      then: Literal.integer(42),
      else: Literal.integer(0)
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("count ? 42 : 0"))
  }

  /// Tests conditional operator with string literals.
  @Test("Conditional operator with string literals generates correct syntax")
  internal func testConditionalOpWithStringLiterals() {
    let conditional = ConditionalOp(
      if: VariableExp("isError"),
      then: Literal.string("Error occurred"),
      else: Literal.string("Success")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isError ? \"Error occurred\" : \"Success\""))
  }

  /// Tests conditional operator with boolean literals.
  @Test("Conditional operator with boolean literals generates correct syntax")
  internal func testConditionalOpWithBooleanLiterals() {
    let conditional = ConditionalOp(
      if: VariableExp("condition"),
      then: Literal.boolean(true),
      else: Literal.boolean(false)
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("condition ? true : false"))
  }

  /// Tests conditional operator with array literals.
  @Test("Conditional operator with array literals generates correct syntax")
  internal func testConditionalOpWithArrayLiterals() {
    let conditional = ConditionalOp(
      if: VariableExp("isFull"),
      then: Literal.array([Literal.string("item1"), Literal.string("item2")]),
      else: Literal.array([])
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isFull ? [\"item1\", \"item2\"] : []"))
  }

  /// Tests conditional operator with dictionary literals.
  @Test("Conditional operator with dictionary literals generates correct syntax")
  internal func testConditionalOpWithDictionaryLiterals() {
    let conditional = ConditionalOp(
      if: VariableExp("hasConfig"),
      then: Literal.dictionary([(Literal.string("key"), Literal.string("value"))]),
      else: Literal.dictionary([])
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("hasConfig ? [\"key\":\"value\"] : [:]"))
  }

  /// Tests conditional operator with tuple expressions.
  @Test("Conditional operator with tuple expressions generates correct syntax")
  internal func testConditionalOpWithTupleExpressions() {
    let conditional = ConditionalOp(
      if: VariableExp("isSuccess"),
      then: Literal.tuple([Literal.string("success"), Literal.integer(200)]),
      else: Literal.tuple([Literal.string("error"), Literal.integer(404)])
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isSuccess ? (\"success\", 200) : (\"error\", 404)"))
  }

  /// Tests conditional operator with nil coalescing.
  @Test("Conditional operator with nil coalescing generates correct syntax")
  internal func testConditionalOpWithNilCoalescing() {
    let conditional = ConditionalOp(
      if: VariableExp("optionalValue"),
      then: VariableExp("optionalValue"),
      else: Literal.string("default")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("optionalValue ? optionalValue : \"default\""))
  }

  /// Tests conditional operator with type casting.
  @Test("Conditional operator with type casting generates correct syntax")
  internal func testConditionalOpWithTypeCasting() {
    let conditional = ConditionalOp(
      if: VariableExp("isString"),
      then: VariableExp("value as String"),
      else: VariableExp("value as Int")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isString ? value as String : value as Int"))
  }

  /// Tests conditional operator with closure expressions.
  @Test("Conditional operator with closure expressions generates correct syntax")
  internal func testConditionalOpWithClosureExpressions() {
    let conditional = ConditionalOp(
      if: VariableExp("useAsync"),
      then: Closure(body: { VariableExp("asyncResult") }),
      else: Closure(body: { VariableExp("syncResult") })
    )

    let syntax = conditional.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("useAsync ? { asyncResult } : { syncResult }".normalize()))
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
