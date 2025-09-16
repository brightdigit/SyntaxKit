//
//  StructureExtractor.swift
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

/// Utility for extracting structural information from SwiftSyntax nodes.
///
/// StructureExtractor handles the complex logic of analyzing syntax node layouts,
/// extracting properties, and converting them into a simplified structure format
/// suitable for JSON serialization. It handles different node structure types
/// (layout, collection, choices) and processes their properties appropriately.
internal enum StructureExtractor {
  // MARK: - String Constants

  /// Placeholder text for missing or nil syntax elements.
  private static let nilValue = "nil"

  /// Property name for collection element type information.
  private static let element = "Element"

  /// Property name for collection count information.
  private static let count = "Count"

  // MARK: - Structure Extraction

  /// Extracts structural information from a SwiftSyntax node.
  ///
  /// This method analyzes the node's internal structure and converts it into
  /// a simplified format with named properties and values. It handles different
  /// structure types (layout, collection, choices) and processes their properties
  /// according to their specific requirements.
  ///
  /// - Parameters:
  ///   - node: The SwiftSyntax node to analyze
  ///   - treeNode: The TreeNode to populate with structure information
  ///   - allChildren: All child nodes of the syntax node
  internal static func extractStructure(
    from node: Syntax,
    into treeNode: any TreeNodeProtocol,
    allChildren: SyntaxChildren
  ) {
    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      // Handle nodes with fixed structure (most syntax nodes)
      handleLayoutStructure(
        node: node,
        treeNode: treeNode,
        keyPaths: keyPaths,
        allChildren: allChildren
      )
    case .collection(let syntax):
      // Handle collection nodes (lists, arrays, etc.)
      handleCollectionStructure(
        node: node,
        treeNode: treeNode,
        elementType: syntax,
        allChildren: allChildren
      )
    case .choices:
      // Handle choice nodes (union types) - no special processing needed
      break
    }
  }

  // MARK: - Layout Structure Handling

  /// Handles structure extraction for layout-based syntax nodes.
  ///
  /// Layout nodes have a fixed set of named properties (like function parameters,
  /// variable names, etc.). This method iterates through each property, extracts
  /// its value, and creates appropriate StructureProperty entries.
  ///
  /// - Parameters:
  ///   - node: The syntax node to process
  ///   - treeNode: The TreeNode to populate
  ///   - keyPaths: The layout key paths to process
  ///   - allChildren: All child nodes for reference checking
  private static func handleLayoutStructure(
    node: Syntax,
    treeNode: any TreeNodeProtocol,
    keyPaths: [AnyKeyPath],
    allChildren: SyntaxChildren
  ) {
    guard let syntaxNode = node.as(node.syntaxNodeType) else {
      return
    }

    for keyPath in keyPaths {
      guard let name = childName(keyPath) else { continue }

      // Check if this property has an actual child node
      guard allChildren.contains(where: { child in child.keyPathInParent == keyPath }) else {
        // Property exists but has no value - mark as nil
        treeNode.structure.append(
          StructureProperty(
            name: name,
            value: StructureValue(text: nilValue)
          )
        )
        continue
      }

      // Extract the actual property value
      let keyPath = keyPath as AnyKeyPath
      switch syntaxNode[keyPath: keyPath] {
      case let value as TokenSyntax:
        // Handle token nodes (keywords, identifiers, operators, etc.)
        treeNode.structure.append(
          StructureProperty(
            name: name,
            value: StructureValue(
              text: value.text,
              kind: "\(value.tokenKind)"
            )
          )
        )
      case let value?:
        if let value = value as? any SyntaxProtocol {
          // Handle nested syntax nodes - store type reference
          let type = "\(value.syntaxNodeType)"
          treeNode.structure.append(
            StructureProperty(
              name: name,
              value: StructureValue(text: "\(type)"),
              ref: "\(type)"
            )
          )
        } else {
          // Handle primitive values
          treeNode.structure.append(
            StructureProperty(name: name, value: StructureValue(text: "\(value)"))
          )
        }
      case .none:
        // Property exists but is nil
        treeNode.structure.append(StructureProperty(name: name))
      }
    }
  }

  // MARK: - Collection Structure Handling

  /// Handles structure extraction for collection-based syntax nodes.
  ///
  /// Collection nodes contain multiple elements of the same type (like parameter lists,
  /// statement blocks, etc.). This method extracts metadata about the collection
  /// including element type and count information.
  ///
  /// - Parameters:
  ///   - node: The syntax node to process
  ///   - treeNode: The TreeNode to populate
  ///   - elementType: The type of elements in the collection
  ///   - allChildren: All child nodes for counting
  private static func handleCollectionStructure(
    node: Syntax,
    treeNode: any TreeNodeProtocol,
    elementType: Any.Type,
    allChildren: SyntaxChildren
  ) {
    // Mark as collection type
    treeNode.type = .collection

    // Add element type information
    treeNode.structure.append(
      StructureProperty(
        name: element,
        value: StructureValue(text: "\(elementType)")
      )
    )

    // Add count information
    treeNode.structure.append(
      StructureProperty(
        name: count,
        value: StructureValue(text: "\(allChildren.count)")
      )
    )
  }
}
