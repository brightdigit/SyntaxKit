//
//  CatchBuilder.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax

/// A result builder for creating catch clauses in a do-catch statement.
///
/// `CatchBuilder` enables the creation of multiple catch clauses using Swift's result builder syntax.
/// It's used in conjunction with the ``Do`` struct to build comprehensive error handling blocks.
///
/// ## Overview
///
/// The `CatchBuilder` implements the result builder pattern to allow for declarative construction
/// of catch clauses. It supports various catch clause types including:
/// - Pattern-based catch clauses (e.g., `catch .specificError`)
/// - Catch clauses with associated values (e.g., `catch .error(let code, let message)`)
/// - General catch clauses (e.g., `catch`)
///
/// ## Usage
///
/// ```swift
/// Do {
///   // Code that may throw
///   try someFunction()
/// } catch: {
///   Catch(EnumCase("networkError")) {
///     Call("handleNetworkError")()
///   }
///   Catch(EnumCase("validationError").associatedValue("field", type: "String")) {
///     Call("handleValidationError") {
///       ParameterExp(name: "field", value: VariableExp("field"))
///     }
///   }
///   Catch {
///     Call("handleGenericError")()
///   }
/// }
/// ```
///
/// ## Result Builder Methods
///
/// The builder provides several methods that implement the result builder protocol:
/// - `buildBlock`: Combines multiple catch clauses into a list
/// - `buildExpression`: Converts individual catch expressions
/// - `buildOptional`: Handles optional catch clauses
/// - `buildEither`: Supports conditional catch clauses
/// - `buildArray`: Handles array-based catch clause construction
///
/// ## Integration with SwiftSyntax
///
/// The builder produces `CatchClauseListSyntax` which is directly compatible with SwiftSyntax's
/// `DoStmtSyntax`, enabling seamless integration with the Swift compiler's syntax tree.
@resultBuilder
public enum CatchBuilder: Sendable, Equatable {
  /// Combines multiple catch clauses into a `CatchClauseListSyntax`.
  ///
  /// This method is called by the result builder when multiple catch clauses are provided
  /// in the catch block. It creates a list of catch clauses that can be attached to a do statement.
  ///
  /// - Parameter components: The catch clauses to combine.
  /// - Returns: A `CatchClauseListSyntax` containing all the provided catch clauses.
  public static func buildBlock(_ components: CatchClauseSyntax...) -> CatchClauseListSyntax {
    CatchClauseListSyntax(components)
  }

  /// Converts a `CatchClauseSyntax` expression into a catch clause.
  ///
  /// This method handles direct `CatchClauseSyntax` instances, allowing for custom
  /// catch clause construction when needed.
  ///
  /// - Parameter expression: The catch clause syntax to convert.
  /// - Returns: The same catch clause syntax.
  public static func buildExpression(_ expression: CatchClauseSyntax) -> CatchClauseSyntax {
    expression
  }

  /// Converts a ``Catch`` instance into a `CatchClauseSyntax`.
  ///
  /// This method handles ``Catch`` struct instances, converting them into the appropriate
  /// syntax representation. This is the most common use case when working with the DSL.
  ///
  /// - Parameter expression: The `Catch` instance to convert.
  /// - Returns: A `CatchClauseSyntax` representing the catch clause.
  public static func buildExpression(_ expression: Catch) -> CatchClauseSyntax {
    expression.catchClauseSyntax
  }

  /// Handles optional catch clauses in conditional contexts.
  ///
  /// This method supports conditional catch clause construction, allowing for
  /// catch clauses that may or may not be included based on runtime conditions.
  ///
  /// - Parameter component: An optional catch clause.
  /// - Returns: The optional catch clause, unchanged.
  public static func buildOptional(_ component: CatchClauseSyntax?) -> CatchClauseSyntax? {
    component
  }

  /// Handles the first branch of a conditional catch clause.
  ///
  /// This method supports `if-else` constructs within catch blocks, allowing for
  /// conditional error handling logic.
  ///
  /// - Parameter component: The catch clause for the first branch.
  /// - Returns: The catch clause syntax.
  public static func buildEither(first component: CatchClauseSyntax) -> CatchClauseSyntax {
    component
  }

  /// Handles the second branch of a conditional catch clause.
  ///
  /// This method supports `if-else` constructs within catch blocks, allowing for
  /// conditional error handling logic.
  ///
  /// - Parameter component: The catch clause for the second branch.
  /// - Returns: The catch clause syntax.
  public static func buildEither(second component: CatchClauseSyntax) -> CatchClauseSyntax {
    component
  }

  /// Combines an array of catch clauses into a `CatchClauseListSyntax`.
  ///
  /// This method supports array-based catch clause construction, useful for
  /// dynamic catch clause generation or when working with collections of catch patterns.
  ///
  /// - Parameter components: An array of catch clauses to combine.
  /// - Returns: A `CatchClauseListSyntax` containing all the catch clauses.
  public static func buildArray(_ components: [CatchClauseSyntax]) -> CatchClauseListSyntax {
    CatchClauseListSyntax(components)
  }
}
