//
//  PoundIf.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

public import SwiftSyntax

/// A `#if … #elseif … #else … #endif` conditional compilation block.
public struct PoundIf: CodeBlock, Sendable {
  /// One of the three accepted condition forms attached to a `#if` / `#elseif` clause.
  internal enum ConditionForm: Sendable {
    case helper(any Condition)
    case raw(String)
    case codeBlock(any CodeBlock)
  }

  /// A single `#if`, `#elseif`, or `#else` clause and the code blocks inside it.
  internal struct Clause: Sendable {
    internal let condition: ConditionForm?
    internal let body: [any CodeBlock]
  }

  private let head: Clause
  private var elseifClauses: [Clause] = []
  private var elseBody: [any CodeBlock]?

  /// The SwiftSyntax representation of this conditional compilation block.
  public var syntax: any SyntaxProtocol {
    var clauses: [IfConfigClauseSyntax] = [
      Self.makeClause(
        poundKeyword: .poundIfToken(trailingTrivia: .space),
        condition: head.condition,
        body: head.body
      )
    ]

    for clause in elseifClauses {
      clauses.append(
        Self.makeClause(
          poundKeyword: .poundElseifToken(leadingTrivia: .newline, trailingTrivia: .space),
          condition: clause.condition,
          body: clause.body
        )
      )
    }

    if let elseBody = elseBody {
      clauses.append(
        Self.makeClause(
          poundKeyword: .poundElseToken(leadingTrivia: .newline, trailingTrivia: .newline),
          condition: nil,
          body: elseBody
        )
      )
    }

    return IfConfigDeclSyntax(
      clauses: IfConfigClauseListSyntax(clauses),
      poundEndif: .poundEndifToken(leadingTrivia: .newline)
    )
  }

  /// `#if <Condition>` using the helper enum.
  /// - Parameters:
  ///   - condition: The structured condition for the `#if` clause.
  ///   - content: The code blocks to emit when the condition is satisfied.
  public init(
    _ condition: some Condition,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) {
    self.head = Clause(condition: .helper(condition), body: content())
  }

  /// `#if <raw>` escape hatch for any expression the helper enum cannot express.
  /// - Parameters:
  ///   - condition: The raw condition text to emit after `#if`.
  ///   - content: The code blocks to emit when the condition is satisfied.
  public init(
    _ condition: String,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) {
    self.head = Clause(condition: .raw(condition), body: content())
  }

  /// `#if <CodeBlock>` escape hatch for callers that already have an expression value.
  /// - Parameters:
  ///   - condition: The expression-shaped condition for the `#if` clause.
  ///   - content: The code blocks to emit when the condition is satisfied.
  public init(
    _ condition: any CodeBlock,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) {
    self.head = Clause(condition: .codeBlock(condition), body: content())
  }

  /// Append a `#elseif <Condition>` clause.
  /// - Parameters:
  ///   - condition: The structured condition for the new `#elseif` clause.
  ///   - content: The code blocks to emit when the condition is satisfied.
  /// - Returns: A copy of `self` with the new clause appended.
  public func elseif(
    _ condition: some Condition,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) -> Self {
    var copy = self
    copy.elseifClauses.append(Clause(condition: .helper(condition), body: content()))
    return copy
  }

  /// Append a `#elseif <raw>` clause.
  /// - Parameters:
  ///   - condition: The raw condition text to emit after `#elseif`.
  ///   - content: The code blocks to emit when the condition is satisfied.
  /// - Returns: A copy of `self` with the new clause appended.
  public func elseif(
    _ condition: String,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) -> Self {
    var copy = self
    copy.elseifClauses.append(Clause(condition: .raw(condition), body: content()))
    return copy
  }

  /// Append a `#elseif <CodeBlock>` clause.
  /// - Parameters:
  ///   - condition: The expression-shaped condition for the new `#elseif` clause.
  ///   - content: The code blocks to emit when the condition is satisfied.
  /// - Returns: A copy of `self` with the new clause appended.
  public func elseif(
    _ condition: any CodeBlock,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) -> Self {
    var copy = self
    copy.elseifClauses.append(Clause(condition: .codeBlock(condition), body: content()))
    return copy
  }

  /// Append a `#else` clause.
  /// - Parameter content: The code blocks to emit when no earlier clause was satisfied.
  /// - Returns: A copy of `self` with the `#else` clause set.
  public func `else`(
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) -> Self {
    var copy = self
    copy.elseBody = content()
    return copy
  }
}
