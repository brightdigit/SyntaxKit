//
//  OptionalChainingLiteralTests.swift
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

/// Test suite for OptionalChainingExp literal functionality.
///
/// This test suite covers the optional chaining expression functionality
/// with literal values (e.g., `constant?`, `[1, 2, 3]?`) in SyntaxKit.
internal final class OptionalChainingLiteralTests {
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
}
