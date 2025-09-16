//
//  TreeNodeProtocol+Extensions.swift
//  Lint
//
//  Created by Leo Dion on 9/16/25.
//

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
  // MARK: - Structure Extraction

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
  package func appendStructure(
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

  // MARK: - Layout Structure Appending

  /// Appends structure properties for layout-based syntax nodes.
  ///
  /// Layout nodes have a fixed set of named properties (like function parameters,
  /// variable names, etc.). This method iterates through each property, extracts
  /// its value, and appends appropriate StructureProperty entries to the structure array.
  ///
  /// - Parameters:
  ///   - node: The syntax node to process
  ///   - keyPaths: The layout key paths to process
  ///   - allChildren: All child nodes for reference checking
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

  /// Appends a structure property for a single key path from a syntax node.
  ///
  /// This method handles the extraction of a single property value from a syntax node,
  /// including checking for child node existence, handling different value types
  /// (tokens, syntax nodes, primitives), and appending appropriate StructureProperty
  /// entries to the structure array.
  ///
  /// - Parameters:
  ///   - keyPath: The key path to process
  ///   - syntaxNode: The syntax node to extract the value from
  ///   - allChildren: All child nodes for reference checking
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

  // MARK: - Collection Structure Appending

  /// Appends structure properties for collection-based syntax nodes.
  ///
  /// Collection nodes contain multiple elements of the same type (like parameter lists,
  /// statement blocks, etc.). This method appends metadata about the collection
  /// including element type and count information to the structure array.
  ///
  /// - Parameters:
  ///   - node: The syntax node to process
  ///   - elementType: The type of elements in the collection
  ///   - allChildren: All child nodes for counting
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

  /// Creates a human-readable name from a SwiftSyntax key path.
  ///
  /// This initializer attempts to derive a meaningful property name from a key path
  /// by converting it to a string and extracting the last component.
  ///
  /// - Parameter keyPath: The key path to extract a name from
  /// - Returns: A string representation of the property name, or nil if extraction fails
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
