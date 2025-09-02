# Troubleshooting SyntaxKit

A comprehensive guide for diagnosing and solving common issues when using SyntaxKit for Swift code generation.

## Overview

This guide addresses the most common problems developers encounter when using SyntaxKit, providing step-by-step solutions and prevention strategies. Whether you're debugging compilation errors, optimizing performance, or troubleshooting macro development, this guide will help you resolve issues quickly.

**What's Covered:**
- Common compilation errors and their solutions
- SwiftSyntax integration problems and fixes
- Performance issues and optimization techniques
- Generated code debugging strategies
- Macro development gotchas and solutions
- Version compatibility and migration issues

> 💡 **Quick Help**: For immediate assistance, check the [FAQ section](#frequently-asked-questions) at the bottom of this guide.

## Common Compilation Errors

### 1. Infix Operator Errors

**Error**: `Infix.InfixError.wrongOperandCount(expected: 2, got: 1)`

**Cause**: Infix operators require exactly two operands.

```swift
// ❌ Incorrect - only one operand
let invalid = try Infix("+") {
    VariableExp("x")
}

// ✅ Correct - two operands
let valid = try Infix("+") {
    VariableExp("x")
    VariableExp("y")
}
```

**Solution**: Always provide exactly two operands for infix expressions.

### 2. Enum Case Pattern Matching Errors

**Error**: Catch patterns don't match thrown errors

**Cause**: Missing enum type qualification or incorrect case names.

```swift
// ❌ Unqualified enum case - won't match MyError.networkFailure
Catch(EnumCase("networkFailure")) { ... }

// ✅ Fully qualified enum case
Catch(EnumCase("MyError.networkFailure")) { ... }
```

**Solution**: Always use fully qualified enum case names.

### 3. Associated Value Binding Issues

**Error**: Associated values not accessible in catch blocks

**Cause**: Missing or incorrect associated value declarations.

```swift
// ❌ Associated values not bound
Catch(EnumCase("ValidationError.fieldError")) {
    // Can't access field name here
}

// ✅ Properly bound associated values
Catch(EnumCase("ValidationError.fieldError").associatedValue("field", type: "String")) {
    Call("print") {
        ParameterExp(unlabeled: Literal.string("Error in field: \\(field)"))
    }
}
```

### 4. Empty Condition Defaults

**Issue**: Guard and If statements with no conditions generate `guard true` or `if true`

```swift
// This generates "guard true else { ... }"
let guardStatement = Guard {
    Return { Literal.string("executed") }
}

// This generates "if true { ... }"
let ifStatement = If {
    Return { Literal.string("executed") }
}
```

**Solution**: Always provide explicit conditions for control flow statements.

## SwiftSyntax Integration Issues

### 1. Version Compatibility Problems

**Issue**: SwiftSyntax version conflicts causing build failures

**Solution**: Pin specific SwiftSyntax versions in Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1")
]
```

**Best Practice**: Use the same SwiftSyntax version that SyntaxKit was built against.

### 2. Parser Integration Errors

**Issue**: Generated code fails SwiftSyntax parsing validation

**Debugging Approach**:

```swift
// Step 1: Generate the code
let generatedCode = myCodeBlock.generateCode()
print("Generated code:")
print(generatedCode)

// Step 2: Validate with SwiftSyntax parser
do {
    let sourceFile = try Parser.parse(source: generatedCode)
    print("✅ Syntax is valid")
} catch {
    print("❌ Syntax error: \(error)")
    // Examine the specific parsing error
}
```

### 3. AST Node Type Mismatches

**Issue**: Generated AST nodes don't match expected SwiftSyntax types

**Solution**: Inspect the actual node types:

```swift
let codeBlock = Function("test") { ... }
let syntax = codeBlock.syntax

// Check the actual type
print("Node type: \(type(of: syntax))")

// Cast to expected type safely
if let funcDecl = syntax.as(FunctionDeclSyntax.self) {
    print("Function name: \(funcDecl.name.text)")
} else {
    print("❌ Not a function declaration")
}
```

## Performance Issues

### 1. Memory Usage Problems

**Issue**: High memory consumption during large code generation

**Symptoms**:
- App crashes with memory pressure warnings
- Slow performance when generating many code structures
- Gradual memory increase during batch operations

**Solutions**:

```swift
// Use autoreleasepool for large generations
autoreleasepool {
    let largeGenerator = Group {
        for i in 0..<1000 {
            Struct("Model\(i)") { ... }
        }
    }
    let output = largeGenerator.generateCode()
    try output.write(to: outputURL, atomically: true, encoding: .utf8)
}

// Break large operations into chunks
func generateInChunks<T>(_ items: [T], chunkSize: Int = 100) -> Group {
    return Group {
        for chunk in items.chunked(into: chunkSize) {
            autoreleasepool {
                Group {
                    for item in chunk {
                        generateStructure(for: item)
                    }
                }
            }
        }
    }
}
```

### 2. Slow Generation Performance

**Issue**: Code generation takes too long for reasonable-sized inputs

**Optimization Strategies**:

```swift
// Cache common patterns
private static let commonImports: [Import] = [
    Import("Foundation"),
    Import("Combine"),
    Import("SwiftUI")
]

// Batch related operations
let apiModule = Group {
    commonImports
    generateAllEndpoints(from: config)
    generateAllModels(from: config)
}

// Use lazy generation for optional content
struct LazyGenerator {
    func generateIfNeeded(_ condition: Bool) -> CodeBlock? {
        guard condition else { return nil }
        return expensiveGeneration()
    }
}
```

### 3. Build Time Issues

**Issue**: Swift compilation is slow due to generated code complexity

**Solutions**:

```swift
// Break large generated files into modules
// Instead of one 10,000-line file:
let hugeFile = Group { /* thousands of declarations */ }

// Create multiple smaller files:
let endpointsModule = Group { /* endpoint declarations */ }
let modelsModule = Group { /* model declarations */ }
let errorsModule = Group { /* error declarations */ }
```

## Debugging Generated Code

### 1. Syntax Validation Workflow

**Step 1: Generate and Inspect**
```swift
let codeBlock = Do {
    Call("riskyOperation").throwing()
} catch: {
    Catch(EnumCase("MyError.specific")) { ... }
}

let generated = codeBlock.generateCode()
print("Generated code:")
print(generated)
```

**Step 2: Parse with SwiftSyntax**
```swift
do {
    let parsed = try Parser.parse(source: generated)
    print("✅ Syntax is valid")
} catch {
    print("❌ Parse error: \(error)")
}
```

**Step 3: Test Compilation**
```bash
# Save to temporary file and test
echo "$generated_code" > temp.swift
swift -parse temp.swift
```

### 2. Pattern Debugging

**Issue**: Catch patterns don't match as expected

**Debugging Process**:

```swift
// Step 1: Test pattern in isolation
let pattern = EnumCase("MyError.validation").associatedValue("field", type: "String")
print("Pattern generates: \(pattern.generateCode())")

// Step 2: Verify against actual error definition
// Ensure your error enum matches:
enum MyError: Error {
    case validation(field: String)  // Must match pattern structure
}

// Step 3: Test complete catch clause
let catchClause = Catch(pattern) {
    Call("print") {
        ParameterExp(unlabeled: Literal.string("Validation failed for: \\(field)"))
    }
}
print("Full catch: \(catchClause.generateCode())")
```

### 3. Result Builder Issues

**Issue**: Code blocks don't combine correctly in result builders

**Common Problems**:
- Empty result builder blocks
- Mixing statement and expression contexts
- Incorrect return types

**Debugging Approach**:

```swift
// Break complex builders into components
let errorHandler = Group {
    Catch(EnumCase("SpecificError")) { ... }
    Catch { ... }
}

// Test each component separately
print("Error handler generates:")
print(errorHandler.generateCode())

// Then combine
let fullBlock = Do {
    // main operation
} catch: {
    errorHandler
}
```

### 4. Integration Testing

**Issue**: Generated code compiles but behaves incorrectly at runtime

**Testing Strategy**:

```swift
@Test("Generated code has correct runtime behavior")
func testRuntimeBehavior() throws {
    let generator = MyGenerator()
    let generated = generator.generate(from: testConfig)
    
    // Write to executable script
    let testScript = """
        \(generated.generateCode())
        
        // Test the generated functionality
        let result = MyGeneratedType.performOperation()
        print("Result: \\(result)")
        """
    
    let output = try executeSwiftScript(testScript)
    #expect(output.contains("Expected result"))
}
```

## Macro Development Gotchas

### 1. Macro Expansion Debugging

**Issue**: Macro doesn't expand as expected in Xcode

**Debugging Steps**:

```swift
// In your macro implementation
public struct MyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Add debug output during development
        print("Macro input: \(node)")
        
        let generated = myCodeGenerator.generate(from: node)
        let code = generated.generateCode()
        
        print("Generated code: \(code)")
        
        // Parse back to ensure validity
        guard let expr = try? Parser.parseExpression(source: code) else {
            throw MacroError.invalidSyntax(code)
        }
        
        return expr
    }
}
```

### 2. Macro Diagnostic Issues

**Issue**: Poor error messages when macro fails

**Solution**: Provide clear diagnostics:

```swift
// In macro expansion
if someValidationFails {
    context.diagnose(
        Diagnostic(
            node: node,
            message: MacroError.validationFailed("Specific reason for failure"),
            severity: .error
        )
    )
    throw MacroError.validationFailed("Detailed error message")
}
```

### 3. Macro Testing Challenges

**Issue**: Difficult to test macro behavior

**Testing Pattern**:

```swift
@Test("Macro generates expected code")
func testMacroExpansion() throws {
    // Test the underlying SyntaxKit generator directly
    let generator = MyMacroGenerator()
    let result = generator.generate(from: testInput)
    
    let expected = """
        func generatedFunction() -> String {
            return "test"
        }
        """
    
    #expect(result.generateCode().normalize() == expected.normalize())
}
```

## Version Compatibility Issues

### 1. Swift Version Compatibility

**Issue**: Code generation differs between Swift versions

**Current Requirements**:
- Swift 6.1+ required
- Xcode 16.4+ for development
- SwiftSyntax 601.0.1+

**Migration Issues**:
```swift
// Swift 6 strict concurrency might affect generated code
// Ensure generated async code is properly marked
Function("fetchData") { ... }
    .async()  // Required marking for Swift 6
    .throws("NetworkError")
```

### 2. SwiftSyntax Version Updates

**Issue**: Breaking changes in SwiftSyntax API

**Solution Pattern**:
```swift
// Check SwiftSyntax version compatibility
#if canImport(SwiftSyntax) && swift(>=6.1)
    // Use modern SwiftSyntax API
    let syntax = codeBlock.syntax
#else
    #error("SyntaxKit requires SwiftSyntax 601.0.1+ and Swift 6.1+")
#endif
```

### 3. Platform-Specific Issues

**Issue**: Generated code works on some platforms but not others

**Common Causes**:
- Missing framework imports for specific platforms
- Platform-specific API availability
- Different default behaviors across platforms

**Solution**:
```swift
// Add platform-specific imports conditionally
let imports = Group {
    Import("Foundation")
    #if os(iOS)
    Import("UIKit")
    #elseif os(macOS) 
    Import("AppKit")
    #endif
}
```

## Prevention Strategies

### 1. Validation Checklist

Before committing generated code:

- [ ] **Syntax Check**: `swift -parse generated_file.swift`
- [ ] **Compilation Check**: `swift build`
- [ ] **Test Execution**: `swift test`
- [ ] **Linting**: `./Scripts/lint.sh` (if available)
- [ ] **Manual Review**: Verify generated code matches expectations

### 2. Automated Quality Gates

**Pre-commit Hook Example**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔍 Validating generated code..."

# Generate fresh code
swift run code-generator

# Validate syntax
for file in Sources/*/Generated/*.swift; do
    if ! swift -parse "$file"; then
        echo "❌ Syntax error in $file"
        exit 1
    fi
done

# Compile test
if ! swift build; then
    echo "❌ Generated code compilation failed"
    exit 1
fi

echo "✅ All validations passed"
```

### 3. Testing Strategies

**Comprehensive Test Coverage**:

```swift
@Test("Edge case: Empty configuration")
func testEmptyConfiguration() throws {
    let generator = APIGenerator()
    let emptyConfig = APIConfiguration(endpoints: [])
    
    // Should handle gracefully, not crash
    let result = generator.generate(from: emptyConfig)
    let code = result.generateCode()
    
    // Should generate valid but empty enum
    #expect(code.contains("enum") && code.contains("{}"))
}

@Test("Edge case: Special characters in names")
func testSpecialCharacters() throws {
    let config = APIConfiguration(endpoints: [
        Endpoint(name: "user-profile", path: "user/profile"),  // Hyphen
        Endpoint(name: "oauth2Token", path: "oauth2/token")     // Numbers
    ])
    
    let generator = APIGenerator()
    let result = generator.generate(from: config)
    
    // Verify special characters are handled correctly
    let code = result.generateCode()
    #expect(code.contains("case userProfile"))  // Camel case conversion
    #expect(code.contains("case oauth2Token"))   // Numbers preserved
}
```

## Frequently Asked Questions

### Build and Compilation Issues

**Q: "My generated code won't compile - how do I debug this?"**

A: Follow this systematic approach:

1. **Check syntax first**: `swift -parse YourGeneratedFile.swift`
2. **Examine the raw generated code**: Add `print(codeBlock.generateCode())` 
3. **Validate with SwiftSyntax parser**: `try Parser.parse(source: generated)`
4. **Test minimal reproduction**: Create the simplest possible case that fails

**Q: "I'm getting 'cannot find type X in scope' errors"**

A: This usually means missing imports. Check that your generator includes necessary imports:

```swift
let module = Group {
    Import("Foundation")        // For basic types
    Import("Combine")          // For publishers
    Import("SwiftUI")          // For UI components
    
    // Your generated code here
}
```

### SwiftSyntax Integration

**Q: "How do I debug complex SwiftSyntax AST issues?"**

A: Use the built-in AST inspection tools:

```swift
let codeBlock = yourComplexGenerator()
let syntax = codeBlock.syntax

// Print AST structure
print("AST: \(syntax.debugDescription)")

// Navigate specific nodes
if let funcDecl = syntax.as(FunctionDeclSyntax.self) {
    print("Function: \(funcDecl.name.text)")
    print("Parameters: \(funcDecl.signature.parameterClause.parameters.count)")
}
```

### Performance and Memory

**Q: "SyntaxKit is using too much memory during generation"**

A: Implement memory management strategies:

```swift
// For large batch operations
autoreleasepool {
    let batchResult = generateManyStructures()
    processBatchResult(batchResult)
}

// For iterative generation
func generateLargeSet() -> Group {
    return Group {
        for batch in largeDatabatched(into: 100) {
            autoreleasepool {
                generateBatch(batch)
            }
        }
    }
}
```

### Testing Generated Code

**Q: "How do I test that my generated code actually works?"**

A: Use a multi-level testing approach:

```swift
// Level 1: String comparison
#expect(generated.normalize() == expected.normalize())

// Level 2: Syntax validation  
let parsed = try Parser.parse(source: generated)
#expect(parsed.statements.count > 0)

// Level 3: Compilation test
let tempFile = writeToTempFile(generated)
let compileResult = try runSwiftParse(tempFile)
#expect(compileResult.success)

// Level 4: Runtime behavior test
let output = try executeGeneratedCode(generated)
#expect(output.contains("expected behavior"))
```

### Macro Development

**Q: "My macro isn't expanding in Xcode - what's wrong?"**

A: Check these common issues:

1. **Registration**: Ensure macro is properly registered in Package.swift
2. **Syntax**: Verify macro call syntax matches declaration
3. **Imports**: Check that macro module is imported
4. **Debugging**: Add print statements to see if macro is being called

```swift
// Add temporary debugging to your macro
public static func expansion(...) throws -> ExprSyntax {
    print("🔧 Macro called with: \(node)")
    // Your implementation
    let result = generate(from: node)
    print("🔧 Generated: \(result.generateCode())")
    return result.syntax
}
```

**Q: "How do I handle macro compilation errors gracefully?"**

A: Implement proper error handling in your macro:

```swift
public static func expansion(...) throws -> ExprSyntax {
    do {
        let generated = myGenerator.generate(from: node)
        return generated.syntax.as(ExprSyntax.self)!
    } catch let error as GenerationError {
        // Provide helpful diagnostic
        context.diagnose(
            Diagnostic(
                node: node,
                message: "Code generation failed: \(error.localizedDescription)",
                severity: .error
            )
        )
        throw error
    }
}
```

### Migration from Manual SwiftSyntax

**Q: "How do I migrate from manual SwiftSyntax to SyntaxKit?"**

A: Follow this incremental migration strategy:

1. **Identify repetitive patterns** in your manual SwiftSyntax code
2. **Start with simple structures** like basic functions or properties
3. **Test equivalence** between manual and SyntaxKit versions
4. **Migrate section by section** rather than all at once
5. **Keep manual code as reference** until migration is complete

**Before (Manual SwiftSyntax)**:
```swift
let funcDecl = FunctionDeclSyntax(
    name: .identifier("test"),
    signature: FunctionSignatureSyntax(
        parameterClause: ParameterClauseSyntax(
            parameters: FunctionParameterListSyntax([...])
        )
    ),
    body: CodeBlockSyntax(statements: [...])
)
```

**After (SyntaxKit)**:
```swift
let function = Function("test") {
    Parameter("param", type: "String")
} _: {
    Return { Literal.string("result") }
}
```

## Getting Help

### Community Resources

- **GitHub Issues**: [SyntaxKit Issues](https://github.com/brightdigit/SyntaxKit/issues)
- **Documentation**: [Complete API Reference](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation)
- **Examples**: Check the `Examples/` directory in the repository

### Reporting Issues

When reporting problems, include:

1. **SyntaxKit version** and **Swift version**
2. **Minimal reproduction case** 
3. **Expected vs actual behavior**
4. **Full error messages** and stack traces
5. **Generated code output** (if applicable)

### Quick Debugging Commands

```bash
# Check SyntaxKit installation
swift package show-dependencies

# Validate generated syntax
swift -parse path/to/generated.swift

# Test compilation
swift build

# Run specific tests
swift test --filter TroubleshootingTests
```

---

> 📖 **See Also**:
> - <doc:Best-Practices> for comprehensive development guidelines
> - <doc:Quick-Start-Guide> for getting started with SyntaxKit
> - <doc:Creating-Macros-with-SyntaxKit> for macro-specific guidance