//
//  ClosureCaptureCoverageTests.swift
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

/// Test suite for improving code coverage of Closure+Capture functionality.
///
/// This test suite focuses on testing edge cases and uncovered code paths
/// in the Closure+Capture extension file to ensure comprehensive test coverage.
internal final class ClosureCaptureCoverageTests {
  // MARK: - Closure+Capture.swift Coverage Tests

  /// Tests fallback cases in CaptureInfo initializers.
  @Test("Capture info fallback cases")
  internal func testCaptureInfoFallbackCases() {
    // Test fallback cases in CaptureInfo initializers

    // Test with unknown reference type (should fallback to weak)
    let unknownRef = ReferenceExp(base: VariableExp("self"), referenceType: "unknown")
    let paramWithUnknownRef = ParameterExp(name: "self", value: unknownRef)
    let closure = Closure(
      capture: { paramWithUnknownRef },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Should fallback to weak
    #expect(description.contains("[weak self]"))
  }

  /// Tests CaptureInfo with non-VariableExp capture expression.
  @Test("Capture info with non VariableExp")
  internal func testCaptureInfoWithNonVariableExp() {
    // Test CaptureInfo with non-VariableExp capture expression
    let initBlock = Init("String")
    let ref = ReferenceExp(base: initBlock, referenceType: "weak")
    let param = ParameterExp(name: "self", value: ref)
    let closure = Closure(
      capture: { param },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Should fallback to "self"
    #expect(description.contains("[weak self]"))
  }

  /// Tests CaptureInfo with non-VariableExp parameter value.
  @Test("Capture info with non VariableExp parameter")
  internal func testCaptureInfoWithNonVariableExpParameter() {
    // Test CaptureInfo with non-VariableExp parameter value
    let initBlock = Init("String")
    let param = ParameterExp(name: "self", value: initBlock)
    let closure = Closure(
      capture: { param },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Should fallback to "self"
    #expect(description.contains("[self]"))
  }
}
