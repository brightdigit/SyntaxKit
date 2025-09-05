//
//  PlusAssignLiteralTests.swift
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

/// Test suite for PlusAssign literal value functionality.
///
/// This test suite covers the `+=` assignment expression functionality
/// with literal values in SyntaxKit.
internal final class PlusAssignLiteralTests {
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

  /// Tests plus assignment with float literal value.
  @Test("Plus assignment with float literal value generates correct syntax")
  internal func testPlusAssignWithFloatLiteralValue() {
    let plusAssign = PlusAssign("value", 3.14)

    let syntax = plusAssign.syntax
    let description = syntax.description

    #expect(description.contains("value += 3.14"))
  }
}
