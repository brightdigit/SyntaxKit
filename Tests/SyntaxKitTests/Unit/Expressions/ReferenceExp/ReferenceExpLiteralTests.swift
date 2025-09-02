//
//  ReferenceExpLiteralTests.swift
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

/// Test suite for ReferenceExp literal functionality.
///
/// This test suite covers the reference expression functionality
/// with literal values in SyntaxKit.
internal final class ReferenceExpLiteralTests {
  /// Tests reference expression with literal base.
  @Test("Reference expression with literal base generates correct syntax")
  internal func testReferenceWithLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.ref("constant"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("constant"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with array literal base.
  @Test("Reference expression with array literal base generates correct syntax")
  internal func testReferenceWithArrayLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.array([Literal.string("item1"), Literal.string("item2")]),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("[\"item1\", \"item2\"]"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with dictionary literal base.
  @Test("Reference expression with dictionary literal base generates correct syntax")
  internal func testReferenceWithDictionaryLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.dictionary([(Literal.string("key"), Literal.string("value"))]),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description.replacingOccurrences(of: " ", with: "")

    #expect(description.contains("[\"key\":\"value\"]".replacingOccurrences(of: " ", with: "")))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with tuple literal base.
  @Test("Reference expression with tuple literal base generates correct syntax")
  internal func testReferenceWithTupleLiteralBase() {
    let reference = ReferenceExp(
      base: Literal.tuple([Literal.string("first"), Literal.string("second")]),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("(\"first\", \"second\")"))
    #expect(reference.captureReferenceType == .weak)
  }
}
