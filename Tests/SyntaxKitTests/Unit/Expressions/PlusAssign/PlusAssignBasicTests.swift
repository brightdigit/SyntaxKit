//
//  PlusAssignBasicTests.swift
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

/// Test suite for basic PlusAssign expression functionality.
///
/// This test suite covers the basic `+=` assignment expression functionality
/// in SyntaxKit.
internal final class PlusAssignBasicTests {
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
}
