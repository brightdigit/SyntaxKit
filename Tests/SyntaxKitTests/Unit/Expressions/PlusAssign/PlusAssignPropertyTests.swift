//
//  PlusAssignPropertyTests.swift
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

/// Test suite for PlusAssign property access functionality.
///
/// This test suite covers the `+=` assignment expression functionality
/// with property access in SyntaxKit.
internal final class PlusAssignPropertyTests {
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
}
