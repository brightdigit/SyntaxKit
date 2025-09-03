//
//  ClosureCoverageTests.swift
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

/// Test suite for improving code coverage of Closure-related functionality.
///
/// This test suite focuses on testing edge cases and uncovered code paths
/// in the Closure extension files to ensure comprehensive test coverage.
internal final class ClosureCoverageTests {
  // MARK: - Closure+Body.swift Coverage Tests

  /// Tests the DeclSyntax case in buildBodyItem method.
  @Test("Build body item with DeclSyntax")
  internal func testBuildBodyItemWithDeclSyntax() {
    // Test the DeclSyntax case in buildBodyItem
    let closure = Closure(body: {
      Variable(.let, name: "test", equals: "value")
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the variable declaration is properly included
    #expect(description.contains("let test  = \"value\""))
  }

  /// Tests the StmtSyntax case in buildBodyItem method.
  @Test("Build body item with StmtSyntax")
  internal func testBuildBodyItemWithStmtSyntax() {
    // Test the StmtSyntax case in buildBodyItem
    let closure = Closure(body: {
      Return {
        VariableExp("value")
      }
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the return statement is properly included
    #expect(description.contains("return value"))
  }

  /// Tests the buildParameterExpressionItem method.
  @Test("Build parameter expression item")
  internal func testBuildParameterExpressionItem() {
    // Test the buildParameterExpressionItem method
    let paramExp = ParameterExp(name: "test", value: "value")
    let closure = Closure(body: {
      paramExp
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter expression is properly included
    #expect(description.contains("value"))
  }

  /// Tests ParameterExp with ExprCodeBlock value.
  @Test("Build parameter expression item with ExprCodeBlock")
  internal func testBuildParameterExpressionItemWithExprCodeBlock() {
    // Test ParameterExp with ExprCodeBlock value
    let initBlock = Init("String")
    let paramExp = ParameterExp(name: "test", value: initBlock)
    let closure = Closure(body: {
      paramExp
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter expression with ExprCodeBlock is properly included
    #expect(description.contains("String()"))
  }

  /// Tests ParameterExp with ExprSyntax value.
  @Test("Build parameter expression item with ExprSyntax")
  internal func testBuildParameterExpressionItemWithExprSyntax() {
    // Test ParameterExp with ExprSyntax value
    let initBlock = Init("String")
    let paramExp = ParameterExp(name: "test", value: initBlock)
    let closure = Closure(body: {
      paramExp
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter expression with ExprSyntax is properly included
    #expect(description.contains("String()"))
  }

  /// Tests ParameterExp with parameter expression syntax.
  @Test("Build parameter expression item with param expr syntax")
  internal func testBuildParameterExpressionItemWithParamExprSyntax() {
    // Test ParameterExp with parameter expression syntax
    let paramExp = ParameterExp(name: "test", value: "value")
    let closure = Closure(body: {
      paramExp
    })

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter expression syntax is properly included
    #expect(description.contains("value"))
  }

  // MARK: - Closure+Signature.swift Coverage Tests

  /// Tests the buildParameterClause method.
  @Test("Build parameter clause")
  internal func testBuildParameterClause() {
    // Test the buildParameterClause method
    let closure = Closure(
      parameters: {
        ClosureParameter("param1", type: "String")
        ClosureParameter("param2", type: "Int")
      },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter clause is properly included
    #expect(description.contains("param1: String"))
    #expect(description.contains("param2: Int"))
  }

  /// Tests the buildParameterSyntax method.
  @Test("Build parameter syntax")
  internal func testBuildParameterSyntax() {
    // Test the buildParameterSyntax method
    let closure = Closure(
      parameters: {
        ClosureParameter("param", type: "String")
      },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter syntax is properly included
    #expect(description.contains("param: String"))
  }

  /// Tests buildParameterSyntax with empty name.
  @Test("Build parameter syntax with empty name")
  internal func testBuildParameterSyntaxWithEmptyName() {
    // Test buildParameterSyntax with empty name
    let closure = Closure(
      parameters: {
        ClosureParameter("", type: "String")
      },
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the parameter syntax handles empty name properly
    #expect(description.contains("String"))
  }

  /// Tests the buildReturnClause method.
  @Test("Build return clause")
  internal func testBuildReturnClause() {
    // Test the buildReturnClause method
    let closure = Closure(
      returns: "String",
      body: {
        Variable(.let, name: "result", equals: "value")
      }
    )

    let syntax = closure.syntax
    let description = syntax.description

    // Verify that the return clause is properly included
    #expect(description.contains("-> String"))
  }
}
