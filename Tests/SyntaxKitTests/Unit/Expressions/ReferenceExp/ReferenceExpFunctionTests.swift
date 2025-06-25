//
//  ReferenceExpFunctionTests.swift
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

/// Test suite for ReferenceExp function call functionality.
///
/// This test suite covers the reference expression functionality
/// with function calls in SyntaxKit.
internal final class ReferenceExpFunctionTests {
  /// Tests reference expression with function call base.
  @Test("Reference expression with function call base generates correct syntax")
  internal func testReferenceWithFunctionCallBase() {
    let reference = ReferenceExp(
      base: Call("getCurrentUser"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getCurrentUser()"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with method call base.
  @Test("Reference expression with method call base generates correct syntax")
  internal func testReferenceWithMethodCallBase() {
    let reference = ReferenceExp(
      base: Call("getData"),
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("getData()"))
    #expect(reference.captureReferenceType == .weak)
  }

  /// Tests reference expression with init call base.
  @Test("Reference expression with init call base generates correct syntax")
  internal func testReferenceWithInitCallBase() {
    let initCall = Init("String")
    let reference = ReferenceExp(
      base: initCall,
      referenceType: .weak
    )

    let syntax = reference.syntax
    let description = syntax.description

    #expect(description.contains("String()"))
    #expect(reference.captureReferenceType == .weak)
  }
}
