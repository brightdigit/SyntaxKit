# SyntaxParser Module Architecture

The SyntaxParser module provides a bridge between Apple's SwiftSyntax framework and
JSON-based tools that need to analyze Swift source code. It transforms the complex
SwiftSyntax AST into a simplified, flat structure suitable for serialization and
external consumption.

## Key Components

### Core Parser (`SyntaxParser`)
- Main entry point for parsing Swift code
- Handles operator precedence folding options
- Orchestrates the parsing pipeline
- Returns JSON-serialized results

### AST Visitor (`TokenVisitor`)
- Implements SwiftSyntax's SyntaxRewriter protocol
- Performs depth-first traversal of the syntax tree
- Extracts essential information from each node
- Builds flattened tree structure with ID-based relationships
- Processes tokens and trivia (whitespace, comments)

### Data Structures
- `TreeNode`: Core representation of syntax elements with metadata
- `StructureProperty`: Named properties within syntax nodes
- `StructureValue`: Terminal values and type references
- `Token`: Token-specific metadata (kind, trivia)
- `SourceRange`: Line/column location coordinates
- `SyntaxType`: Semantic classification of syntax elements
- `SyntaxResponse`: Container for final JSON output (deprecated)

## Processing Pipeline

1. **Parse**: SwiftSyntax parses Swift source code into AST
2. **Transform**: Optional operator precedence folding
3. **Visit**: TokenVisitor traverses AST and extracts data
4. **Classify**: Nodes are semantically classified (decl/expr/pattern/type/other)
5. **Flatten**: Tree structure is flattened using ID references
6. **Serialize**: Result is encoded to JSON format

## Output Format

The JSON output contains a flat array of TreeNode objects, each with:
- Unique ID and parent reference (creates tree structure)
- Semantic type classification for easy filtering
- Source location for mapping back to original code
- Structural properties describing internal organization
- Token metadata for leaf nodes (kind, trivia)

## Design Principles

### Console-First
- Optimized for command-line tools and external analysis
- Plain text output without HTML escaping (as of recent refactor)
- Clean JSON suitable for piping between tools

### Flattened Structure
- Uses ID-based references instead of object nesting
- Avoids circular references in JSON serialization
- Enables efficient access patterns for external tools

### Semantic Classification
- Groups syntax elements by role (declarations, expressions, etc.)
- Simplifies filtering and analysis for consumers
- Abstracts away SwiftSyntax implementation details

### Preservation of Details
- Maintains source location information
- Preserves trivia (whitespace, comments) exactly
- Includes both present and missing tokens for completeness

## Usage Example

```swift
let code = """
    struct User {
        let name: String
    }
    """

let treeNodes = SyntaxParser.parse(code: code)
// treeNodes contains the array of TreeNode objects directly
```

This module is primarily consumed by the `skit` command-line tool for
converting Swift source code to JSON for external analysis and tooling.
