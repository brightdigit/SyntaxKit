//
//  Catch.swift
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

import Foundation
public import SwiftSyntax

/// A Swift `catch` clause for error handling.
public struct Catch: CodeBlock {
  private let pattern: (any CodeBlock)?
  private let body: [any CodeBlock]

  /// Creates a `catch` clause with a pattern.
  /// - Parameters:
  ///   - pattern: The pattern to match for this catch clause.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the catch clause.
  public init(
    _ pattern: any CodeBlock,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) {
    self.pattern = pattern
    self.body = content()
  }

  /// Creates a `catch` clause without a pattern (catches all errors).
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the catch clause.
  public init(@CodeBlockBuilderResult _ content: () -> [any CodeBlock]) {
    self.pattern = nil
    self.body = content()
  }

  /// Creates a `catch` clause for a specific enum case.
  /// - Parameters:
  ///   - enumCase: The enum case to catch.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the catch clause.
  public static func `catch`(
    _ enumCase: EnumCase,
    @CodeBlockBuilderResult _ content: () -> [any CodeBlock]
  ) -> Catch {
    Catch(enumCase, content)
  }

  /// Creates a catch clause.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the catch clause.
  public init(@CodeBlockBuilderResult _ content: () throws -> [any CodeBlock]) rethrows {
    self.pattern = nil
    self.body = try content()
  }

  public var catchClauseSyntax: CatchClauseSyntax {
    // Build catch items (patterns)
    var catchItems: CatchItemListSyntax?
    if let pattern = pattern {
      var patternSyntax: PatternSyntax

      if let enumCase = pattern as? EnumCase {
        if !enumCase.caseAssociatedValues.isEmpty {
          let baseName = enumCase.caseName
          let baseParts = baseName.split(separator: ".")
          let (typeName, caseName) =
            baseParts.count == 2 ? (String(baseParts[0]), String(baseParts[1])) : ("", baseName)
          // Build the pattern: .caseName(let a, let b)
          let memberAccess = MemberAccessExprSyntax(
            base: typeName.isEmpty
              ? nil : ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(typeName))),
            dot: .periodToken(),
            name: .identifier(caseName)
          )
          let patternWithTuple = PatternSyntax(
            ValueBindingPatternSyntax(
              bindingSpecifier: .keyword(.case, trailingTrivia: .space),
              pattern: PatternSyntax(
                ExpressionPatternSyntax(
                  expression: ExprSyntax(memberAccess)
                )
              )
            )
          )
          // Actually, Swift's catch pattern for associated values is: .caseName(let a, let b)
          // So we want: ExpressionPatternSyntax(MemberAccessExprSyntax + tuplePattern)
          let tuplePattern = TuplePatternSyntax(
            leftParen: .leftParenToken(),
            elements: TuplePatternElementListSyntax(
              enumCase.caseAssociatedValues.enumerated().map { index, associated in
                TuplePatternElementSyntax(
                  pattern: PatternSyntax(
                    ValueBindingPatternSyntax(
                      bindingSpecifier: .keyword(.let, trailingTrivia: .space),
                      pattern: PatternSyntax(
                        IdentifierPatternSyntax(identifier: .identifier(associated.name))
                      )
                    )
                  ),
                  trailingComma: index < enumCase.caseAssociatedValues.count - 1
                    ? .commaToken(trailingTrivia: .space) : nil
                )
              }
            ),
            rightParen: .rightParenToken()
          )
          let patternSyntaxExpr = ExprSyntax(
            FunctionCallExprSyntax(
              calledExpression: ExprSyntax(memberAccess),
              leftParen: .leftParenToken(),
              arguments: LabeledExprListSyntax(
                enumCase.caseAssociatedValues.enumerated().map { index, associated in
                  LabeledExprSyntax(
                    label: nil,
                    colon: nil,
                    expression: ExprSyntax(
                      PatternExprSyntax(
                        pattern: PatternSyntax(
                          ValueBindingPatternSyntax(
                            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
                            pattern: PatternSyntax(
                              IdentifierPatternSyntax(identifier: .identifier(associated.name))
                            )
                          )
                        )
                      )
                    ),
                    trailingComma: index < enumCase.caseAssociatedValues.count - 1
                      ? .commaToken(trailingTrivia: .space) : nil
                  )
                }
              ),
              rightParen: .rightParenToken()
            )
          )
          patternSyntax = PatternSyntax(ExpressionPatternSyntax(expression: patternSyntaxExpr))
        } else {
          let enumCaseExpr = enumCase.asExpressionSyntax
          patternSyntax = PatternSyntax(ExpressionPatternSyntax(expression: enumCaseExpr))
        }
      } else {
        // Handle other patterns
        patternSyntax = PatternSyntax(
          ExpressionPatternSyntax(
            expression: ExprSyntax(
              fromProtocol: pattern.syntax.as(ExprSyntax.self)
                ?? DeclReferenceExprSyntax(baseName: .identifier(""))
            )
          )
        )
      }

      catchItems = CatchItemListSyntax([
        CatchItemSyntax(pattern: patternSyntax)
      ])
    }

    // Build catch body
    let catchBody = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap {
          var item: CodeBlockItemSyntax?
          if let decl = $0.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = $0.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = $0.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return item?.with(\.trailingTrivia, .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline, trailingTrivia: .space)
    )

    return CatchClauseSyntax(
      catchKeyword: .keyword(.catch, trailingTrivia: .space),
      catchItems: catchItems ?? CatchItemListSyntax([]),
      body: catchBody
    )
  }

  public var syntax: any SyntaxProtocol {
    catchClauseSyntax
  }
}
