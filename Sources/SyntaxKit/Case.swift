//
//  Case.swift
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

/// A `case` in a `switch` statement with tuple-style patterns, or an enum case declaration.
public struct Case: CodeBlock {
  private let patterns: [PatternConvertible]
  private let body: [CodeBlock]
  private let isEnumCase: Bool
  private let enumCaseName: String?
  private var associatedValue: (name: String, type: String)?

  /// Creates a `case` for a `switch` statement.
  /// - Parameters:
  ///   - patterns: The patterns to match for the case.
  ///   - content: A ``CodeBlockBuilder`` that provides the body of the case.
  public init(_ patterns: PatternConvertible..., @CodeBlockBuilderResult content: () -> [CodeBlock])
  {
    self.patterns = patterns
    self.body = content()
    self.isEnumCase = false
    self.enumCaseName = nil
    self.associatedValue = nil
  }

  /// Creates an enum case declaration.
  /// - Parameter name: The name of the enum case.
  public init(_ name: String) {
    self.patterns = []
    self.body = []
    self.isEnumCase = true
    self.enumCaseName = name
    self.associatedValue = nil
  }

  /// Sets the associated value for the enum case.
  /// - Parameters:
  ///   - name: The name of the associated value.
  ///   - type: The type of the associated value.
  /// - Returns: A copy of the case with the associated value set.
  public func associatedValue(_ name: String, type: String) -> Self {
    var copy = self
    copy.associatedValue = (name: name, type: type)
    return copy
  }

  public var switchCaseSyntax: SwitchCaseSyntax {
    let caseItems = SwitchCaseItemListSyntax(
      patterns.enumerated().map { index, pat in
        var item = SwitchCaseItemSyntax(pattern: pat.patternSyntax)
        if index < patterns.count - 1 {
          item = item.with(\.trailingComma, .commaToken(trailingTrivia: .space))
        }
        return item
      })

    let statements = CodeBlockItemListSyntax(
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
      })
    let label = SwitchCaseLabelSyntax(
      caseKeyword: .keyword(.case, trailingTrivia: .space),
      caseItems: caseItems,
      colon: .colonToken(trailingTrivia: .newline)
    )
    return SwitchCaseSyntax(
      label: .case(label),
      statements: statements
    )
  }

  public var syntax: SyntaxProtocol {
    if isEnumCase {
      // Handle enum case declaration
      let caseKeyword = TokenSyntax.keyword(.case, trailingTrivia: .space)
      let identifier = TokenSyntax.identifier(enumCaseName ?? "", trailingTrivia: .space)

      var parameterClause: EnumCaseParameterClauseSyntax?
      if let associated = associatedValue {
        let parameter = EnumCaseParameterSyntax(
          firstName: nil,
          secondName: .identifier(associated.name),
          colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
          type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(associated.type)))
        )
        parameterClause = EnumCaseParameterClauseSyntax(
          leftParen: .leftParenToken(),
          parameters: EnumCaseParameterListSyntax([parameter]),
          rightParen: .rightParenToken()
        )
      }

      return EnumCaseDeclSyntax(
        caseKeyword: caseKeyword,
        elements: EnumCaseElementListSyntax([
          EnumCaseElementSyntax(
            leadingTrivia: .space,
            _: nil,
            name: associatedValue != nil ? TokenSyntax.identifier(enumCaseName ?? "") : identifier,
            _: nil,
            parameterClause: parameterClause,
            _: nil,
            rawValue: nil,
            _: nil,
            trailingComma: nil,
            trailingTrivia: .newline
          )
        ])
      )
    } else {
      // Handle switch case
      return switchCaseSyntax
    }
  }
}
