//
//  Tuple.swift
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

/// A tuple expression, e.g. `(a, b, c)`.
public struct Tuple: CodeBlock {
  internal let elements: [CodeBlock]
  private var isAsync: Bool = false
  private var isThrowing: Bool = false

  /// Creates a tuple expression comprising the supplied elements.
  /// - Parameter content: A ``CodeBlockBuilder`` producing the tuple elements **in order**.
  /// Elements may be any `CodeBlock` that can be represented as an expression (see
  /// `CodeBlock.expr`).
  public init(@CodeBlockBuilderResult _ content: () -> [CodeBlock]) {
    self.elements = content()
  }

  /// Creates a tuple pattern for switch cases.
  /// - Parameter elements: Array of pattern elements, where `nil` represents a wildcard pattern.
  public static func pattern(_ elements: [PatternConvertible?]) -> TuplePattern {
    TuplePattern(elements: elements)
  }

  /// Creates a tuple pattern that can be used as a CodeBlock.
  /// - Parameter elements: Array of pattern elements, where `nil` represents a wildcard pattern.
  public static func patternCodeBlock(_ elements: [PatternConvertible?]) -> TuplePatternCodeBlock {
    TuplePatternCodeBlock(elements: elements)
  }

  /// Marks this tuple as async.
  /// - Returns: A copy of the tuple marked as async.
  public func async() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }

  /// Marks this tuple as await.
  /// - Returns: A copy of the tuple marked as await.
  public func await() -> Self {
    var copy = self
    copy.isAsync = true
    return copy
  }

  /// Marks this tuple as throwing.
  /// - Returns: A copy of the tuple marked as throwing.
  public func throwing() -> Self {
    var copy = self
    copy.isThrowing = true
    return copy
  }

  public var syntax: SyntaxProtocol {
    let list = TupleExprElementListSyntax(
      elements.enumerated().map { index, block in
        let elementExpr: ExprSyntax
        if isAsync {
          // For async tuples, generate async let syntax for each element
          // This assumes the block is a function call or expression that can be awaited
          elementExpr = ExprSyntax(
            AwaitExprSyntax(
              awaitKeyword: .keyword(.await, trailingTrivia: .space),
              expression: block.expr
            )
          )
        } else {
          elementExpr = block.expr
        }

        return TupleExprElementSyntax(
          label: nil,
          colon: nil,
          expression: elementExpr,
          trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .space) : nil
        )
      }
    )

    let tupleExpr = ExprSyntax(
      TupleExprSyntax(
        leftParen: .leftParenToken(),
        elements: list,
        rightParen: .rightParenToken()
      )
    )

    if isThrowing {
      return ExprSyntax(
        TryExprSyntax(
          tryKeyword: .keyword(.try, trailingTrivia: .space),
          expression: tupleExpr
        )
      )
    } else {
      return tupleExpr
    }
  }
}
