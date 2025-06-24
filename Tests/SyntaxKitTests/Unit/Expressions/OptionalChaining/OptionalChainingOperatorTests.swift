//
//  OptionalChainingOperatorTests.swift
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

/// Test suite for OptionalChainingExp operator functionality.
///
/// This test suite covers the optional chaining expression functionality
/// with various operators in SyntaxKit.
internal final class OptionalChainingOperatorTests {
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
}
