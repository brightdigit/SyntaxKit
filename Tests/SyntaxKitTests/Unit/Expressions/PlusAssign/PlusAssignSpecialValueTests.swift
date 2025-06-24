//
//  PlusAssignSpecialValueTests.swift
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

/// Test suite for PlusAssign special value functionality.
///
/// This test suite covers the `+=` assignment expression functionality
/// with special values in SyntaxKit.
internal final class PlusAssignSpecialValueTests {
  /// Tests plus assignment with nil literal value.
  @Test("Plus assignment with nil literal value generates correct syntax")
  internal func testPlusAssignWithNilLiteralValue() {
    let plusAssign = PlusAssign("optional", Literal.nil)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("optional += nil"))
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
