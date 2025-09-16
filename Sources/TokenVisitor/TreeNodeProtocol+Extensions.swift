//
//  TreeNodeProtocol+Extensions.swift
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

package import SwiftSyntax

extension TreeNodeProtocol {
  package static func parseTree(
    from sourceFile: SourceFileSyntax,
    withFileName fileName: String = .defaultFileName,
    showingMissingTokens: Bool = false
  ) -> [Self] {
    // Use raw syntax tree without precedence folding for simplicity
    let syntax = Syntax(sourceFile)

    // Create visitor to traverse AST and extract structured information
    let visitor = TokenVisitor<Self>(
      locationConverter: SourceLocationConverter(
        fileName: fileName,
        tree: sourceFile
      ),
      showMissingTokens: false
    )

    // Traverse the syntax tree and build our simplified representation
    _ = visitor.rewrite(syntax)

    // Return the tree nodes directly
    return visitor.tree
  }
}

// MARK: - Structure Extraction Extensions

extension TreeNodeProtocol {
  /// Appends structural information from a SwiftSyntax node to the structure array.
  ///
  /// This method analyzes the node's internal structure and converts it into
  /// a simplified format with named properties and values, appending them to
  /// the structure array. It handles different structure types (layout, collection,
  /// choices) and processes their properties according to their specific requirements.
  ///
  /// - Parameters:
  ///   - node: The SwiftSyntax node to analyze
  ///   - allChildren: All child nodes of the syntax node
  internal func appendStructure(
    from node: Syntax,
    allChildren: SyntaxChildren
  ) {
    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      // Handle nodes with fixed structure (most syntax nodes)
      appendLayoutStructure(
        node: node,
        keyPaths: keyPaths,
        allChildren: allChildren
      )
    case .collection(let syntax):
      // Handle collection nodes (lists, arrays, etc.)
      appendCollectionStructure(
        elementType: syntax,
        allChildren: allChildren
      )
    case .choices:
      // Handle choice nodes (union types) - no special processing needed
      break
    }
  }

  private func appendLayoutStructure(
    node: Syntax,
    keyPaths: [AnyKeyPath],
    allChildren: SyntaxChildren
  ) {
    guard let syntaxNode = node.as(node.syntaxNodeType) else {
      return
    }

    for keyPath in keyPaths {
      appendKeyPathProperty(
        keyPath: keyPath,
        syntaxNode: syntaxNode,
        allChildren: allChildren
      )
    }
  }

  private func appendKeyPathValue(_ anyValue: Any?, withName name: String) {
    switch anyValue {
    case let value as TokenSyntax:
      // Handle token nodes (keywords, identifiers, operators, etc.)
      structure.append(
        StructureProperty(
          token: name,
          tokenSyntax: value
        )
      )
    case let value as any SyntaxProtocol:
      // Handle nested syntax nodes - store type reference
      structure.append(
        StructureProperty(reference: name, type: value.syntaxNodeType)
      )
    case let value?:
      // Handle primitive values
      structure.append(
        StructureProperty(primitive: name, value: value)
      )
    case .none:
      // Property exists but is nil
      structure.append(StructureProperty(name: name))
    }
  }

  private func appendKeyPathProperty(
    keyPath: AnyKeyPath,
    syntaxNode: any SyntaxProtocol,
    allChildren: SyntaxChildren
  ) {
    guard let name = String(keyPath) else {
      return
    }

    // Check if this property has an actual child node
    guard allChildren.contains(where: { child in child.keyPathInParent == keyPath }) else {
      // Property exists but has no value - mark as nil
      structure.append(
        StructureProperty(nilValueWithName: name)
      )
      return
    }

    // Extract the actual property value
    let keyPath = keyPath as AnyKeyPath
    appendKeyPathValue(syntaxNode[keyPath: keyPath], withName: name)
  }

  private func appendCollectionStructure(
    elementType: Any.Type,
    allChildren: SyntaxChildren
  ) {
    // Mark as collection type
    type = .collection

    // Add element type information
    structure.append(
      StructureProperty(elementWithType: elementType)
    )

    // Add count information
    structure.append(
      StructureProperty(collectionWithCount: allChildren.count)
    )
  }
}

extension String {
  fileprivate static let defaultFileName = ""

  fileprivate init?(_ keyPath: AnyKeyPath) {
    let keyPathString = String(describing: keyPath)

    // Extract the last component after the last dot
    if let lastDotIndex = keyPathString.lastIndex(of: ".") {
      let afterDot = keyPathString[keyPathString.index(after: lastDotIndex)...]
      self = String(afterDot)
    } else {
      // If no dots found, use the whole string
      guard !keyPathString.isEmpty else {
        return nil
      }
      self = keyPathString
    }
  }
}
