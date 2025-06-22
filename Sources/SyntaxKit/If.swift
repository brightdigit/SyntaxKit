//
//  If.swift
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

/// An `if` statement.
public struct If: CodeBlock {
  private let conditions: [CodeBlock]
  private let body: [CodeBlock]
  private let elseBody: [CodeBlock]?

  /// Creates an `if` statement with optional `else`.
  /// - Parameters:
  ///   - condition: A single `CodeBlock` produced by the builder that describes the `if` condition.
  ///   - then: Builder that produces the body for the `if` branch.
  ///   - elseBody: Builder that produces the body for the `else` branch. The body may contain
  ///               nested `If` instances (representing `else if`) and/or a ``Then`` block for the
  ///               final `else` statements.
  public init(
    @CodeBlockBuilderResult _ condition: () -> [CodeBlock],
    @CodeBlockBuilderResult then: () -> [CodeBlock],
    @CodeBlockBuilderResult else elseBody: () -> [CodeBlock] = { [] }
  ) {
    let allConditions = condition()
    guard !allConditions.isEmpty else {
      fatalError("If requires at least one condition CodeBlock")
    }
    self.conditions = allConditions
    self.body = then()
    let generatedElse = elseBody()
    self.elseBody = generatedElse.isEmpty ? nil : generatedElse
  }

  /// Convenience initializer that keeps the previous API: pass the condition directly.
  public init(
    _ condition: CodeBlock,
    @CodeBlockBuilderResult then: () -> [CodeBlock],
    @CodeBlockBuilderResult else elseBody: () -> [CodeBlock] = { [] }
  ) {
    self.init({ condition }, then: then, else: elseBody)
  }

  public var syntax: SyntaxProtocol {
    // Build list of ConditionElements from all provided conditions
    let condList = ConditionElementListSyntax(
      conditions.enumerated().map {
        index, block in
        let needsComma = index < conditions.count - 1

        func appendComma(
          _ element: ConditionElementSyntax
        ) -> ConditionElementSyntax {
          needsComma ? element.with(\.trailingComma, .commaToken(trailingTrivia: .space)) : element
        }

        if let letCond = block as? Let {
          let element = ConditionElementSyntax(
            condition: .optionalBinding(
              OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(
                  .let,
                  trailingTrivia: .space
                ),
                pattern: IdentifierPatternSyntax(
                  identifier: .identifier(letCond.name)
                ),
                initializer: InitializerClauseSyntax(
                  equal: .equalToken(
                    leadingTrivia: .space,
                    trailingTrivia: .space
                  ),
                  value: letCond.value.syntax.as(ExprSyntax.self)
                    ?? ExprSyntax(
                      DeclReferenceExprSyntax(
                        baseName: .identifier("")
                      )
                    )
                )
              )
            )
          )
          return appendComma(element)
        } else {
          let element = ConditionElementSyntax(
            condition: .expression(
              ExprSyntax(
                fromProtocol: block.syntax.as(ExprSyntax.self)
                  ?? DeclReferenceExprSyntax(
                    baseName: .identifier("")
                  )
              )
            )
          )
          return appendComma(element)
        }
      }
    )
    let bodyBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax(
        body.compactMap {
          var item: CodeBlockItemSyntax?
          if let enumCase = $0 as? EnumCase {
            // Handle EnumCase specially - use expression syntax for enum cases in expressions
            item = CodeBlockItemSyntax(item: .expr(enumCase.exprSyntax))
          } else if let decl = $0.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = $0.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = $0.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          }
          return item?.with(\.trailingTrivia, .newline)
        }
      ),
      rightBrace: .rightBraceToken(leadingTrivia: .newline)
    )
    // swiftlint:disable:next closure_body_length
    let elseBlock: IfExprSyntax.ElseBody? = {
      guard let elseBlocks = elseBody else {
        return nil
      }

      // Build a chained else-if structure if the builder provided If blocks.
      var current: SyntaxProtocol?

      for block in elseBlocks.reversed() {
        switch block {
        case let thenBlock as Then:
          // Leaf `else` – produce a code-block.
          let stmts = CodeBlockItemListSyntax(
            thenBlock.body.compactMap { element in
              if let enumCase = element as? EnumCase {
                // Handle EnumCase specially - use expression syntax for enum cases in expressions
                return CodeBlockItemSyntax(item: .expr(enumCase.exprSyntax)).with(
                  \.trailingTrivia,
                  .newline
                )
              } else if let decl = element.syntax.as(DeclSyntax.self) {
                return CodeBlockItemSyntax(item: .decl(decl)).with(
                  \.trailingTrivia,
                  .newline
                )
              } else if let expr = element.syntax.as(ExprSyntax.self) {
                return CodeBlockItemSyntax(item: .expr(expr)).with(
                  \.trailingTrivia,
                  .newline
                )
              } else if let stmt = element.syntax.as(StmtSyntax.self) {
                return CodeBlockItemSyntax(item: .stmt(stmt)).with(
                  \.trailingTrivia,
                  .newline
                )
              }
              return nil
            }
          )
          let codeBlock = CodeBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
            statements: stmts,
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
          )
          current = codeBlock as SyntaxProtocol

        case let ifBlock as If:
          guard var ifExpr = ifBlock.syntax.as(IfExprSyntax.self) else { continue }
          if let nested = current {
            let elseChoice: IfExprSyntax.ElseBody
            if let codeBlock = nested.as(CodeBlockSyntax.self) {
              elseChoice = IfExprSyntax.ElseBody(codeBlock)
            } else if let nestedIf = nested.as(IfExprSyntax.self) {
              elseChoice = IfExprSyntax.ElseBody(nestedIf)
            } else {
              continue
            }

            ifExpr =
              ifExpr
              .with(\.elseKeyword, .keyword(.else, leadingTrivia: .space, trailingTrivia: .space))
              .with(\.elseBody, elseChoice)
          }
          current = ifExpr as SyntaxProtocol

        default:
          // Treat any other CodeBlock as part of a final code-block
          let item: CodeBlockItemSyntax?
          if let enumCase = block as? EnumCase {
            // Handle EnumCase specially - use expression syntax for enum cases in expressions
            item = CodeBlockItemSyntax(item: .expr(enumCase.exprSyntax))
          } else if let decl = block.syntax.as(DeclSyntax.self) {
            item = CodeBlockItemSyntax(item: .decl(decl))
          } else if let expr = block.syntax.as(ExprSyntax.self) {
            item = CodeBlockItemSyntax(item: .expr(expr))
          } else if let stmt = block.syntax.as(StmtSyntax.self) {
            item = CodeBlockItemSyntax(item: .stmt(stmt))
          } else {
            item = nil
          }
          if let itm = item {
            let codeBlock = CodeBlockSyntax(
              leftBrace: .leftBraceToken(
                leadingTrivia: .space,
                trailingTrivia: .newline
              ),
              statements: CodeBlockItemListSyntax(
                [itm.with(\.trailingTrivia, .newline)]
              ),
              rightBrace: .rightBraceToken(leadingTrivia: .newline)
            )
            current = codeBlock as SyntaxProtocol
          }
        }
      }

      if let final = current {
        if let codeBlock = final.as(CodeBlockSyntax.self) {
          return IfExprSyntax.ElseBody(codeBlock)
        } else if let ifExpr = final.as(IfExprSyntax.self) {
          return IfExprSyntax.ElseBody(ifExpr)
        }
      }
      return nil
    }()
    return ExprSyntax(
      IfExprSyntax(
        ifKeyword: .keyword(.if, trailingTrivia: .space),
        conditions: condList,
        body: bodyBlock,
        elseKeyword: elseBlock != nil
          ? .keyword(.else, leadingTrivia: .space, trailingTrivia: .space) : nil,
        elseBody: elseBlock
      )
    )
  }
}
