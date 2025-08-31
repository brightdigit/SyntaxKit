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

### Package Dependencies
- **SwiftSyntax** (601.0.1+) - Apple's Swift syntax parser
- **SwiftOperators** - Operator handling
- **SwiftParser** - Swift code parsing
- **SwiftDocC Plugin** (1.4.0+) - Documentation generation

### Quality Tools
- **SwiftFormat** (600.0.0) - Code formatting
- **SwiftLint** (0.58.2) - Static analysis (90+ opt-in rules)
- **Periphery** (3.0.1) - Unused code detection

## Project Structure

### Products
1. **SyntaxKit Library** - Main DSL library
2. **skit Executable** - Command-line tool for parsing Swift code to JSON

### Platform Support
- macOS 13.0+, iOS 13.0+, watchOS 6.0+, tvOS 13.0+, visionOS 1.0+
- Swift 6.1+ required
- Xcode 16.4+ for development

### Testing
- Uses modern Swift Testing framework (`@Test` syntax)
- Tests organized by component in `Tests/SyntaxKitTests/Unit/`
- Integration tests in `Tests/SyntaxKitTests/Integration/`
- Comprehensive CI/CD with GitHub Actions

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
- We suggest using the Swift OpenAPI Generator