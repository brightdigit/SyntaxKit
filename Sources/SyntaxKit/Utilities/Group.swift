//
//  Group.swift
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

public import SwiftSyntax

/// A group of code blocks.
public struct Group: CodeBlock {
  internal let members: [CodeBlock]

  /// Creates a group of code blocks.
  /// - Parameter content: A ``CodeBlockBuilder`` that provides the members of the group.
  public init(@CodeBlockBuilderResult _ content: () throws -> [CodeBlock]) rethrows {
    self.members = try content()
  }

  public var syntax: SyntaxProtocol {
    let statements = members.flatMap { block -> [CodeBlockItemSyntax] in
      if let list = block.syntax.as(CodeBlockItemListSyntax.self) {
        return Array(list)
      }

      let item: CodeBlockItemSyntax.Item
      if let decl = block.syntax.as(DeclSyntax.self) {
        item = .decl(decl)
      } else if let stmt = block.syntax.as(StmtSyntax.self) {
        item = .stmt(stmt)
      } else if let expr = block.syntax.as(ExprSyntax.self) {
        item = .expr(expr)
      } else {
        // Skip unsupported syntax types instead of crashing
        // This allows the group to continue processing other valid blocks
        #warning(
          "TODO: Review fallback for unsupported syntax types - consider if this should be an error instead"
        )
        return []
      }
      return [CodeBlockItemSyntax(item: item, trailingTrivia: .newline)]
    }
    return CodeBlockItemListSyntax(statements)
  }
}
