//
//  TokenVisitor.swift
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
@_spi(RawSyntax) import SwiftSyntax

internal final class TokenVisitor: SyntaxRewriter {
  // var list = [String]()
  internal var tree = [TreeNode]()

  private var current: TreeNode!
  private var index = 0

  internal let locationConverter: SourceLocationConverter
  internal let showMissingTokens: Bool

  internal init(locationConverter: SourceLocationConverter, showMissingTokens: Bool) {
    self.locationConverter = locationConverter
    self.showMissingTokens = showMissingTokens
    super.init(viewMode: showMissingTokens ? .all : .sourceAccurate)
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  override internal func visitPre(_ node: Syntax) {
    let syntaxNodeType = node.syntaxNodeType

    let className: String
    if "\(syntaxNodeType)".hasSuffix("Syntax") {
      className = String("\(syntaxNodeType)".dropLast(6))
    } else {
      className = "\(syntaxNodeType)"
    }

    let sourceRange = node.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end

    let graphemeStartColumn: Int
    if let prefix = String(
      locationConverter.sourceLines[start.line - 1].utf8.prefix(start.column - 1)
    ) {
      graphemeStartColumn = prefix.utf16.count + 1
    } else {
      graphemeStartColumn = start.column
    }
    let graphemeEndColumn: Int
    if let prefix = String(
      locationConverter.sourceLines[end.line - 1].utf8.prefix(end.column - 1)
    ) {
      graphemeEndColumn = prefix.utf16.count + 1
    } else {
      graphemeEndColumn = end.column
    }

    let syntaxType: SyntaxType
    switch node {
    case _ where node.is(DeclSyntax.self):
      syntaxType = .decl
    case _ where node.is(ExprSyntax.self):
      syntaxType = .expr
    case _ where node.is(PatternSyntax.self):
      syntaxType = .pattern
    case _ where node.is(TypeSyntax.self):
      syntaxType = .type
    default:
      syntaxType = .other
    }

    let treeNode = TreeNode(
      id: index,
      text: className,
      range: SourceRange(
        startRow: start.line,
        startColumn: start.column,
        endRow: end.line,
        endColumn: end.column
      ),
      type: syntaxType
    )

    tree.append(treeNode)
    index += 1

    let allChildren = node.children(viewMode: .all)

    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      if let syntaxNode = node.as(node.syntaxNodeType) {
        for keyPath in keyPaths {
          guard let name = childName(keyPath) else {
            continue
          }
          guard allChildren.contains(where: { child in child.keyPathInParent == keyPath }) else {
            treeNode.structure.append(
              StructureProperty(name: name, value: StructureValue(text: "nil"))
            )
            continue
          }

          let keyPath = keyPath as AnyKeyPath
          switch syntaxNode[keyPath: keyPath] {
          case let value as TokenSyntax:
            if value.presence == .missing {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: value.text,
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            } else {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: value.text,
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            }
          case let value?:
            if let value = value as? SyntaxProtocol {
              let type = "\(value.syntaxNodeType)"
              treeNode.structure.append(
                StructureProperty(
                  name: name, value: StructureValue(text: "\(type)"), ref: "\(type)"))
            } else {
              treeNode.structure.append(
                StructureProperty(name: name, value: StructureValue(text: "\(value)")))
            }
          case .none:
            treeNode.structure.append(StructureProperty(name: name))
          }
        }
      }
    case .collection(let syntax):
      treeNode.type = .collection
      treeNode.structure.append(
        StructureProperty(name: "Element", value: StructureValue(text: "\(syntax)")))
      treeNode.structure.append(
        StructureProperty(
          name: "Count",
          value: StructureValue(text: "\(node.children(viewMode: .all).count)")
        )
      )
    case .choices:
      break
    }

    if let current {
      treeNode.parent = current.id
    }
    current = treeNode
  }

  override internal func visit(_ token: TokenSyntax) -> TokenSyntax {
    current.text = token
      .text
      .escapeHTML()
      .replaceInvisiblesWithHTML()
      .replaceHTMLWhitespacesWithSymbols()

    current.token = Token(kind: "\(token.tokenKind)", leadingTrivia: "", trailingTrivia: "")

    for piece in token.leadingTrivia {
      let trivia = processTriviaPiece(piece)
      current.token?.leadingTrivia += trivia.replaceHTMLWhitespacesWithSymbols()
    }
    processToken(token)
    for piece in token.trailingTrivia {
      let trivia = processTriviaPiece(piece)
      current.token?.trailingTrivia += trivia.replaceHTMLWhitespacesWithSymbols()
    }

    return token
  }

  override internal func visitPost(_ node: Syntax) {
    if let parent = current.parent {
      current = tree[parent]
    } else {
      current = nil
    }
  }
}
