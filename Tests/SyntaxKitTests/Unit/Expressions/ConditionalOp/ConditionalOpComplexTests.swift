//
//  ConditionalOpComplexTests.swift
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

/// Test suite for ConditionalOp complex expression functionality.
///
/// This test suite covers the conditional operator expression
/// with complex expressions in SyntaxKit.
internal final class ConditionalOpComplexTests {
  /// Tests conditional operator with function calls.
  @Test("Conditional operator with function calls generates correct syntax")
  internal func testConditionalOpWithFunctionCalls() {
    let conditional = ConditionalOp(
      if: Call("isValid"),
      then: Call("processValid"),
      else: Call("handleInvalid")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isValid() ? processValid() : handleInvalid()"))
  }

  /// Tests conditional operator with property access.
  @Test("Conditional operator with property access generates correct syntax")
  internal func testConditionalOpWithPropertyAccess() {
    let conditional = ConditionalOp(
      if: PropertyAccessExp(base: VariableExp("user"), propertyName: "isAdmin"),
      then: PropertyAccessExp(base: VariableExp("user"), propertyName: "adminSettings"),
      else: PropertyAccessExp(base: VariableExp("user"), propertyName: "defaultSettings")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("user.isAdmin ? user.adminSettings : user.defaultSettings"))
  }

  /// Tests conditional operator with nil coalescing.
  @Test("Conditional operator with nil coalescing generates correct syntax")
  internal func testConditionalOpWithNilCoalescing() {
    let conditional = ConditionalOp(
      if: VariableExp("optionalValue"),
      then: VariableExp("optionalValue"),
      else: Literal.string("default")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("optionalValue ? optionalValue : \"default\""))
  }

  /// Tests conditional operator with type casting.
  @Test("Conditional operator with type casting generates correct syntax")
  internal func testConditionalOpWithTypeCasting() {
    let conditional = ConditionalOp(
      if: VariableExp("isString"),
      then: VariableExp("value as String"),
      else: VariableExp("value as Int")
    )

    let syntax = conditional.syntax
    let description = syntax.description

    #expect(description.contains("isString ? value as String : value as Int"))
  }

  /// Tests conditional operator with closure expressions.
  @Test("Conditional operator with closure expressions generates correct syntax")
  internal func testConditionalOpWithClosureExpressions() {
    let conditional = ConditionalOp(
      if: VariableExp("useAsync"),
      then: Closure(body: { VariableExp("asyncResult") }),
      else: Closure(body: { VariableExp("syncResult") })
    )

    let syntax = conditional.syntax
    let description = syntax.description.normalize()

    #expect(description.contains("useAsync ? { asyncResult } : { syncResult }".normalize()))
  }
}
