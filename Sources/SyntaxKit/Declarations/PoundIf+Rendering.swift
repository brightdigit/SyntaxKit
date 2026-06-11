//
//  PoundIf+Rendering.swift
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

internal import SwiftParser
internal import SwiftSyntax

extension PoundIf {
  internal static func makeClause(
    poundKeyword: TokenSyntax,
    condition: ConditionForm?,
    body: [any CodeBlock]
  ) -> IfConfigClauseSyntax {
    let items = CodeBlockItemListSyntax(
      body.compactMap { block -> CodeBlockItemSyntax? in
        CodeBlockItemSyntax.Item.create(from: block.syntax).map {
          CodeBlockItemSyntax(item: $0, trailingTrivia: .newline)
        }
      }
    )

    let renderedCondition = condition.flatMap(Self.renderCondition)?
      .with(\.trailingTrivia, .newline)

    return IfConfigClauseSyntax(
      poundKeyword: poundKeyword,
      condition: renderedCondition,
      elements: .statements(items)
    )
  }

  private static func renderCondition(_ form: ConditionForm) -> ExprSyntax? {
    switch form {
    case .helper(let condition):
      return parseExpression(renderHelper(condition, atTopLevel: true))
    case .raw(let text):
      return parseExpression(text)
    case .codeBlock(let block):
      if let expr = block.syntax.as(ExprSyntax.self) {
        return expr
      }
      return parseExpression(block.generateCode())
    }
  }

  private static func parseExpression(_ source: String) -> ExprSyntax? {
    let file = Parser.parse(source: source)
    for item in file.statements {
      if let expr = item.item.as(ExprSyntax.self) {
        return expr
      }
    }
    return nil
  }

  private static func renderHelper(_ condition: Condition, atTopLevel: Bool) -> String {
    if let leaf = renderLeaf(condition) {
      return leaf
    }
    return renderCombinator(condition, atTopLevel: atTopLevel)
  }

  private static func renderLeaf(_ condition: Condition) -> String? {
    switch condition {
    case .canImport(let module): return "canImport(\(module))"
    case .flag(let name): return name
    case .os(let value): return "os(\(value.rawValue))"
    case .arch(let value): return "arch(\(value.rawValue))"
    case .targetEnvironment(let value): return "targetEnvironment(\(value.rawValue))"
    case .swift(let check): return "swift(\(check.rendered))"
    case .compiler(let check): return "compiler(\(check.rendered))"
    case .hasFeature(let name): return "hasFeature(\(name))"
    case .hasAttribute(let name): return "hasAttribute(\(name))"
    case .and, .or, .not: return nil
    }
  }

  private static func renderCombinator(_ condition: Condition, atTopLevel: Bool) -> String {
    switch condition {
    case .and(let lhs, let rhs):
      let inner =
        "\(renderHelper(lhs, atTopLevel: false)) && \(renderHelper(rhs, atTopLevel: false))"
      return atTopLevel ? inner : "(\(inner))"
    case .or(let lhs, let rhs):
      let inner =
        "\(renderHelper(lhs, atTopLevel: false)) || \(renderHelper(rhs, atTopLevel: false))"
      return atTopLevel ? inner : "(\(inner))"
    case .not(let operand):
      return "!\(renderHelper(operand, atTopLevel: false))"
    default:
      return ""
    }
  }
}
