//
//  ConditionalOpLiteralTests.swift
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

/// Test suite for ConditionalOp literal functionality.
///
/// This test suite covers the conditional operator expression
/// with literal values in SyntaxKit.
internal final class ConditionalOpLiteralTests {
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
}
