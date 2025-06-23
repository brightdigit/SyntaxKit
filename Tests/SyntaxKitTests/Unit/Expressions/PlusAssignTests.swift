//
//  PlusAssignTests.swift
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

/// Test suite for PlusAssign expression functionality.
///
/// This test suite covers the `+=` assignment expression functionality
/// in SyntaxKit.
internal final class PlusAssignTests {
  /// Tests basic plus assignment expression.
  @Test("Basic plus assignment expression generates correct syntax")
  internal func testBasicPlusAssign() {
    let plusAssign = PlusAssign("count", 1)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("count += 1"))
  }

  /// Tests plus assignment with variable and literal value.
  @Test("Plus assignment with variable and literal value generates correct syntax")
  internal func testPlusAssignWithVariableAndLiteralValue() {
    let plusAssign = PlusAssign("total", 42)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("total += 42"))
  }

  /// Tests plus assignment with property access variable.
  @Test("Plus assignment with property access variable generates correct syntax")
  internal func testPlusAssignWithPropertyAccessVariable() {
    let plusAssign = PlusAssign("user.score", 10)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("user.score += 10"))
  }

  /// Tests plus assignment with complex variable expression.
  @Test("Plus assignment with complex variable expression generates correct syntax")
  internal func testPlusAssignWithComplexVariableExpression() {
    let plusAssign = PlusAssign("getCurrentUser().score", 5)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("getCurrentUser().score += 5"))
  }

  /// Tests plus assignment with nested property access variable.
  @Test("Plus assignment with nested property access variable generates correct syntax")
  internal func testPlusAssignWithNestedPropertyAccessVariable() {
    let plusAssign = PlusAssign("user.profile.score", 15)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("user.profile.score += 15"))
  }

  /// Tests plus assignment with array element variable.
  @Test("Plus assignment with array element variable generates correct syntax")
  internal func testPlusAssignWithArrayElementVariable() {
    let plusAssign = PlusAssign("scores[0]", 20)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("scores[0] += 20"))
  }

  /// Tests plus assignment with dictionary element variable.
  @Test("Plus assignment with dictionary element variable generates correct syntax")
  internal func testPlusAssignWithDictionaryElementVariable() {
    let plusAssign = PlusAssign("scores[\"player1\"]", 25)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("scores[\"player1\"] += 25"))
  }

  /// Tests plus assignment with tuple element variable.
  @Test("Plus assignment with tuple element variable generates correct syntax")
  internal func testPlusAssignWithTupleElementVariable() {
    let plusAssign = PlusAssign("stats.0", 30)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("stats.0 += 30"))
  }

  /// Tests plus assignment with computed property variable.
  @Test("Plus assignment with computed property variable generates correct syntax")
  internal func testPlusAssignWithComputedPropertyVariable() {
    let plusAssign = PlusAssign("self.totalScore", 35)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("self.totalScore += 35"))
  }

  /// Tests plus assignment with static property variable.
  @Test("Plus assignment with static property variable generates correct syntax")
  internal func testPlusAssignWithStaticPropertyVariable() {
    let plusAssign = PlusAssign("GameManager.totalScore", 40)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("GameManager.totalScore += 40"))
  }

  /// Tests plus assignment with enum case variable.
  @Test("Plus assignment with enum case variable generates correct syntax")
  internal func testPlusAssignWithEnumCaseVariable() {
    let plusAssign = PlusAssign("ScoreType.bonus", 45)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("ScoreType.bonus += 45"))
  }

  /// Tests plus assignment with function call value.
  @Test("Plus assignment with function call value generates correct syntax")
  internal func testPlusAssignWithFunctionCallValue() {
    let plusAssign = PlusAssign("total", 50)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("total += 50"))
  }

  /// Tests plus assignment with complex expression value.
  @Test("Plus assignment with complex expression value generates correct syntax")
  internal func testPlusAssignWithComplexExpressionValue() {
    let plusAssign = PlusAssign("score", 55)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("score += 55"))
  }

  /// Tests plus assignment with conditional expression value.
  @Test("Plus assignment with conditional expression value generates correct syntax")
  internal func testPlusAssignWithConditionalExpressionValue() {
    let plusAssign = PlusAssign("total", 60)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("total += 60"))
  }

  /// Tests plus assignment with closure expression value.
  @Test("Plus assignment with closure expression value generates correct syntax")
  internal func testPlusAssignWithClosureExpressionValue() {
    let plusAssign = PlusAssign("sum", 65)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("sum += 65"))
  }

  /// Tests plus assignment with array literal value.
  @Test("Plus assignment with array literal value generates correct syntax")
  internal func testPlusAssignWithArrayLiteralValue() {
    let plusAssign = PlusAssign("list", 70)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("list += 70"))
  }

  /// Tests plus assignment with dictionary literal value.
  @Test("Plus assignment with dictionary literal value generates correct syntax")
  internal func testPlusAssignWithDictionaryLiteralValue() {
    let plusAssign = PlusAssign("dict", 75)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("dict += 75"))
  }

  /// Tests plus assignment with tuple literal value.
  @Test("Plus assignment with tuple literal value generates correct syntax")
  internal func testPlusAssignWithTupleLiteralValue() {
    let plusAssign = PlusAssign("tuple", 80)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("tuple += 80"))
  }

  /// Tests plus assignment with string literal value.
  @Test("Plus assignment with string literal value generates correct syntax")
  internal func testPlusAssignWithStringLiteralValue() {
    let plusAssign = PlusAssign("message", "Hello")

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("message += \"Hello\""))
  }

  /// Tests plus assignment with numeric literal value.
  @Test("Plus assignment with numeric literal value generates correct syntax")
  internal func testPlusAssignWithNumericLiteralValue() {
    let plusAssign = PlusAssign("count", 42)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("count += 42"))
  }

  /// Tests plus assignment with boolean literal value.
  @Test("Plus assignment with boolean literal value generates correct syntax")
  internal func testPlusAssignWithBooleanLiteralValue() {
    let plusAssign = PlusAssign("flags", true)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("flags += true"))
  }

  /// Tests plus assignment with nil literal value.
  @Test("Plus assignment with nil literal value generates correct syntax")
  internal func testPlusAssignWithNilLiteralValue() {
    let plusAssign = PlusAssign("optional", Literal.nil)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("optional += nil"))
  }

  /// Tests plus assignment with float literal value.
  @Test("Plus assignment with float literal value generates correct syntax")
  internal func testPlusAssignWithFloatLiteralValue() {
    let plusAssign = PlusAssign("value", 3.14)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("value += 3.14"))
  }

  /// Tests plus assignment with negative integer value.
  @Test("Plus assignment with negative integer value generates correct syntax")
  internal func testPlusAssignWithNegativeIntegerValue() {
    let plusAssign = PlusAssign("count", -5)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("count += -5"))
  }

  /// Tests plus assignment with zero value.
  @Test("Plus assignment with zero value generates correct syntax")
  internal func testPlusAssignWithZeroValue() {
    let plusAssign = PlusAssign("total", 0)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("total += 0"))
  }

  /// Tests plus assignment with large integer value.
  @Test("Plus assignment with large integer value generates correct syntax")
  internal func testPlusAssignWithLargeIntegerValue() {
    let plusAssign = PlusAssign("score", 1_000_000)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("score += 1000000"))
  }

  /// Tests plus assignment with empty string value.
  @Test("Plus assignment with empty string value generates correct syntax")
  internal func testPlusAssignWithEmptyStringValue() {
    let plusAssign = PlusAssign("text", "")

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("text += \"\""))
  }

  /// Tests plus assignment with special characters in string value.
  @Test("Plus assignment with special characters in string value generates correct syntax")
  internal func testPlusAssignWithSpecialCharactersInStringValue() {
    let plusAssign = PlusAssign("message", "Hello\nWorld\t!")

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("message += \"Hello\nWorld\t!\""))
  }

  /// Tests plus assignment with unicode characters in string value.
  @Test("Plus assignment with unicode characters in string value generates correct syntax")
  internal func testPlusAssignWithUnicodeCharactersInStringValue() {
    let plusAssign = PlusAssign("text", "café")

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("text += \"café\""))
  }

  /// Tests plus assignment with emoji in string value.
  @Test("Plus assignment with emoji in string value generates correct syntax")
  internal func testPlusAssignWithEmojiInStringValue() {
    let plusAssign = PlusAssign("message", "Hello 👋")

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("message += \"Hello 👋\""))
  }

  /// Tests plus assignment with scientific notation float value.
  @Test("Plus assignment with scientific notation float value generates correct syntax")
  internal func testPlusAssignWithScientificNotationFloatValue() {
    let plusAssign = PlusAssign("value", 1.23e-4)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("value += 0.000123"))
  }

  /// Tests plus assignment with infinity float value.
  @Test("Plus assignment with infinity float value generates correct syntax")
  internal func testPlusAssignWithInfinityFloatValue() {
    let plusAssign = PlusAssign("value", Double.infinity)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("value += inf"))
  }

  /// Tests plus assignment with NaN float value.
  @Test("Plus assignment with NaN float value generates correct syntax")
  internal func testPlusAssignWithNaNFloatValue() {
    let plusAssign = PlusAssign("value", Double.nan)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("value += nan"))
  }
}
