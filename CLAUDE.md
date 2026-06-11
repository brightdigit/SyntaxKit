# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SyntaxKit is a Swift package that provides a declarative DSL for generating Swift code using result builders. Built on SwiftSyntax, it allows programmatic creation of Swift code structures (structs, enums, classes, functions) in a type-safe manner.

## Essential Commands

### Build & Test
```bash
# Build the package
swift build

# Run all tests
swift test

# Run specific test
swift test --filter TestName

# Run tests with coverage
swift test --enable-code-coverage
```

### Code Quality
```bash
# Run comprehensive linting (SwiftFormat, SwiftLint, Periphery)
./Scripts/lint.sh

# Format code only (skip other checks)
LINT_MODE=NONE ./Scripts/lint.sh
```

### Documentation
```bash
# Generate DocC documentation
swift package generate-documentation
```

## Architecture

### Core Design Patterns
- **Result Builders**: Declarative DSL using `@resultBuilder` for Swift code generation
- **Protocol-Oriented**: `CodeBlock` protocol as foundation for all syntax elements
- **SwiftSyntax Integration**: All components generate native SwiftSyntax AST nodes

### Key Protocols
- `CodeBlock` - Core protocol for all syntax elements
- `PatternConvertible` - For pattern matching constructs  
- `TypeRepresentable` - For type system integration

### Source Organization
```
Sources/SyntaxKit/
├── Core/           # Fundamental protocols and builders
├── Declarations/   # Type declarations (Class, Struct, Enum, etc.)
├── Expressions/    # Swift expressions and operators
├── Functions/      # Function definitions and method calls
├── Variables/      # Variable and property declarations
├── ControlFlow/    # Control flow constructs (Switch, If, For)
├── Collections/    # Array, dictionary helpers
├── Parameters/     # Function parameter handling
├── Patterns/       # Pattern matching constructs
├── Utilities/      # Helper functions and extensions
└── ErrorHandling/  # Error handling constructs
```

## Development Workflow

### Adding New Syntax Elements
1. Create source file in appropriate subdirectory
2. Implement `CodeBlock` protocol
3. Add corresponding unit tests in `Tests/SyntaxKitTests/Unit/`
4. Run `./Scripts/lint.sh` to ensure code quality
5. Run `swift test` to verify functionality

### Coding Conventions
- **No global functions or variables.** Every function and `let`/`var` must be
  nested inside a type (`struct`/`enum`/`class`) or an `extension`. This includes
  declarations that look indented only because they sit inside a `#if … #endif`
  conditional-compilation block (e.g. `Sources/skit/Runner.swift`) — those are
  still file-scope globals and must be moved into a type. This is not currently
  enforced by SwiftLint: a `custom_rules` regex can't reliably distinguish a
  global nested in `#if` from a legitimate type member, so it needs an
  AST-aware (SwiftSyntax) check to enforce. Until then, follow the rule by hand.

### Package Dependencies
- **SwiftSyntax** (601.0.1+) - Apple's Swift syntax parser
- **SwiftOperators** - Operator handling
- **SwiftParser** - Swift code parsing
- **SwiftDocC Plugin** (1.4.0+) - Documentation generation

### Quality Tools
- **SwiftFormat** (602.0.0) - Code formatting
- **SwiftLint** (0.63.2) - Static analysis (90+ opt-in rules)
- **Periphery** (3.7.2) - Unused code detection

## Project Structure

### Products
1. **SyntaxKit Library** - Main DSL library
2. **skit Executable** - Command-line tool for parsing Swift code to JSON

### Platform Support
- Swift 6.1+ required
- Xcode 16.3+ for development

### Testing
- Uses modern Swift Testing framework (`@Test` syntax)
- Tests organized by component in `Tests/SyntaxKitTests/Unit/`
- Integration tests in `Tests/SyntaxKitTests/Integration/`
- Comprehensive CI/CD with GitHub Actions

## SwiftSyntax Reference

> **Full Documentation**: [SwiftSyntax 601.0.1 Documentation](https://swiftpackageindex.com/swiftlang/swift-syntax/601.0.1/documentation/swiftsyntax)  
> **Local Reference**: [docs/SwiftSyntax-LLM.md](Docs/SwiftSyntax-LLM.md) - Complete SwiftSyntax API reference (590KB)

### Core Concepts
SwiftSyntax is Apple's source-accurate tree representation of Swift source code, enabling parsing, inspection, generation, and transformation of Swift code programmatically.

### Key Types & Protocols

#### Syntax Foundation
- `Syntax` - Base protocol for all syntax nodes
- `SyntaxProtocol` - Protocol all syntax nodes conform to
- `SyntaxCollection` - Collection of syntax nodes
- `SyntaxChildren` - Collection of child syntax nodes

#### Tokens & Trivia
- `TokenSyntax` - Single token representation
- `TokenKind` - Enumerates Swift language token types
- `Trivia` - Whitespace, comments, and other non-semantic content
- `TriviaPiece` - Individual trivia element
- `SourcePresence` - Indicates if node was found in source

#### Major Syntax Categories

**Declarations (`DeclSyntax`)**
- `ClassDeclSyntax` - Class declarations
- `StructDeclSyntax` - Struct declarations  
- `EnumDeclSyntax` - Enum declarations
- `ProtocolDeclSyntax` - Protocol declarations
- `FunctionDeclSyntax` - Function declarations
- `VariableDeclSyntax` - Variable declarations
- `ImportDeclSyntax` - Import statements
- `ExtensionDeclSyntax` - Extension declarations
- `TypeAliasDeclSyntax` - Type alias declarations
- `AssociatedTypeDeclSyntax` - Associated type declarations
- `OperatorDeclSyntax` - Operator declarations
- `PrecedenceGroupDeclSyntax` - Precedence group declarations
- `MacroDeclSyntax` - Macro declarations
- `MacroExpansionDeclSyntax` - Macro expansion declarations

**Expressions (`ExprSyntax`)**
- `FunctionCallExprSyntax` - Function calls
- `MemberAccessExprSyntax` - Member access (dot notation)
- `SubscriptCallExprSyntax` - Subscript calls
- `BinaryOperatorExprSyntax` - Binary operators
- `PrefixOperatorExprSyntax` - Prefix operators
- `PostfixOperatorExprSyntax` - Postfix operators
- `TernaryExprSyntax` - Ternary operator expressions
- `ArrayExprSyntax` - Array literals
- `DictionaryExprSyntax` - Dictionary literals
- `StringLiteralExprSyntax` - String literals
- `IntegerLiteralExprSyntax` - Integer literals
- `FloatLiteralExprSyntax` - Float literals
- `BooleanLiteralExprSyntax` - Boolean literals
- `NilLiteralExprSyntax` - Nil literals
- `ClosureExprSyntax` - Closure expressions
- `IfExprSyntax` - If expressions
- `SwitchExprSyntax` - Switch expressions
- `TryExprSyntax` - Try expressions
- `AwaitExprSyntax` - Await expressions
- `KeyPathExprSyntax` - Key path expressions
- `RegexLiteralExprSyntax` - Regex literals

**Statements (`StmtSyntax`)**
- `ExpressionStmtSyntax` - Expression statements
- `IfStmtSyntax` - If statements
- `GuardStmtSyntax` - Guard statements
- `WhileStmtSyntax` - While loops
- `ForStmtSyntax` - For loops
- `RepeatStmtSyntax` - Repeat-while loops
- `DoStmtSyntax` - Do statements
- `ReturnStmtSyntax` - Return statements
- `ThrowStmtSyntax` - Throw statements
- `BreakStmtSyntax` - Break statements
- `ContinueStmtSyntax` - Continue statements
- `DeferStmtSyntax` - Defer statements
- `DiscardStmtSyntax` - Discard statements
- `YieldStmtSyntax` - Yield statements

**Types (`TypeSyntax`)**
- `IdentifierTypeSyntax` - Named types
- `ArrayTypeSyntax` - Array types
- `DictionaryTypeSyntax` - Dictionary types
- `TupleTypeSyntax` - Tuple types
- `FunctionTypeSyntax` - Function types
- `AttributedTypeSyntax` - Types with attributes
- `OptionalTypeSyntax` - Optional types
- `ImplicitlyUnwrappedOptionalTypeSyntax` - IUO types
- `CompositionTypeSyntax` - Protocol composition types
- `PackExpansionTypeSyntax` - Pack expansion types
- `PackElementTypeSyntax` - Pack element types
- `MetatypeTypeSyntax` - Metatype types

**Patterns (`PatternSyntax`)**
- `IdentifierPatternSyntax` - Identifier patterns
- `ExpressionPatternSyntax` - Expression patterns
- `ValueBindingPatternSyntax` - Value binding patterns
- `TuplePatternSyntax` - Tuple patterns
- `WildcardPatternSyntax` - Wildcard patterns
- `IsTypePatternSyntax` - Type checking patterns

#### Collections & Lists
- `AttributeListSyntax` - Attribute lists
- `CodeBlockItemListSyntax` - Code block items
- `MemberBlockItemListSyntax` - Member block items
- `ParameterListSyntax` - Parameter lists
- `GenericParameterListSyntax` - Generic parameter lists
- `GenericRequirementListSyntax` - Generic requirement lists
- `SwitchCaseListSyntax` - Switch case lists
- `CatchClauseListSyntax` - Catch clause lists
- `ArrayElementListSyntax` - Array element lists
- `DictionaryElementListSyntax` - Dictionary element lists

#### Visitors & Transformers
- `SyntaxVisitor` - Base visitor class for traversing syntax trees
- `SyntaxAnyVisitor` - Generic visitor for any syntax node
- `SyntaxRewriter` - Transformer for modifying syntax trees
- `SyntaxTreeViewMode` - Controls how missing/unexpected nodes are handled

### Common Patterns

#### Creating Syntax Nodes
```swift
// Create a simple identifier
let identifier = TokenSyntax.identifier("myVariable")

// Create a string literal
let stringLiteral = StringLiteralExprSyntax(
    openingQuote: .stringQuoteToken(),
    segments: StringLiteralSegmentListSyntax([
        StringSegmentSyntax(content: .stringSegment("Hello"))
    ]),
    closingQuote: .stringQuoteToken()
)

// Create a function call
let functionCall = FunctionCallExprSyntax(
    calledExpression: DeclReferenceExprSyntax(
        baseName: .identifier("print")
    ),
    leftParen: .leftParenToken(),
    arguments: LabeledExprListSyntax([
        LabeledExprSyntax(expression: stringLiteral)
    ]),
    rightParen: .rightParenToken()
)
```

#### Traversing Syntax Trees
```swift
class MyVisitor: SyntaxVisitor {
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        print("Found function: \(node.name)")
        return .visitChildren
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        print("Found variable declaration")
        return .visitChildren
    }
}

// Usage
let visitor = MyVisitor()
visitor.walk(syntaxTree)
```

#### Modifying Syntax Trees
```swift
class MyRewriter: SyntaxRewriter {
    override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
        // Transform string literals
        let newContent = node.segments.map { segment in
            // Modify content as needed
            return segment
        }
        return node.with(\.segments, StringLiteralSegmentListSyntax(newContent))
    }
}

// Usage
let rewriter = MyRewriter()
let modifiedTree = rewriter.visit(syntaxTree)
```

### Integration with SyntaxKit

When working with SyntaxKit, remember:
- All `CodeBlock` implementations should generate valid SwiftSyntax nodes
- Use the appropriate SwiftSyntax types for each language construct
- Leverage SwiftSyntax's type safety for compile-time validation
- Consider using `SyntaxRewriter` for complex transformations
- Use `SyntaxVisitor` for analysis and inspection tasks

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
- We suggest using the Swift OpenAPI Generator
