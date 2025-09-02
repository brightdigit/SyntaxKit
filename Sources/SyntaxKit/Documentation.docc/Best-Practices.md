# Best Practices for SyntaxKit

A comprehensive guide for effective code generation using SyntaxKit's declarative DSL.

## Overview

This guide consolidates best practices for using SyntaxKit effectively, covering the essential patterns and strategies for building robust, maintainable code generators. Whether you're developing Swift macros, building API client generators, or creating developer tools, these practices will help you avoid common pitfalls and create reliable code generation systems.

**What You'll Learn:**
- Error handling patterns and debugging strategies
- Integration approaches for different project types
- Code organization for maintainable generators
- Comprehensive testing strategies
- Performance optimization techniques
- Common anti-patterns to avoid

> 💡 **Quick Start**: If you're new to SyntaxKit, start with our <doc:Quick-Start-Guide> tutorial, then return here for advanced patterns and best practices.
>
> 🛠️ **Hands-On Learning**: See these practices in action with our <doc:EnumGenerator> example and <doc:Creating-Macros-with-SyntaxKit> tutorial.

## When to Use SyntaxKit

### ✅ Perfect Use Cases

**Swift Macro Development:**
- Replace complex AST manipulation with declarative syntax
- Reduce macro code by 60-80% while improving readability
- Eliminate most AST construction errors

**API Client Generation:**
- Transform OpenAPI specs into type-safe Swift networking code
- Generate hundreds of endpoints from configuration files
- Maintain perfect synchronization between API changes and Swift code

**Model Generation:**
- Convert database schemas or JSON schemas into Swift data models
- Generate computed properties, validation logic, and serialization code
- Handle complex type relationships and constraints

**Migration Utilities:**
- Build tools that automatically transform legacy code structures
- Migrate between different architectural patterns
- Update deprecated APIs across large codebases

**Developer Tools:**
- Create code generators for repetitive patterns and boilerplate
- Build custom language extensions and DSLs
- Generate test fixtures and mock data

### ❌ When NOT to Use SyntaxKit

**Standard Application Development:**
- Writing business logic, view controllers, or standard app features
- One-time scripts or simple utilities
- Performance-critical code where generation overhead matters
- Teams unfamiliar with result builder patterns

**Decision Framework:**
```
Are you generating Swift code programmatically?
├─ YES: Building macros, tools, or generators? → Use SyntaxKit
└─ NO: Writing application logic? → Use regular Swift
```

## Error Handling and Debugging

### Common Error Patterns

SyntaxKit provides robust error handling constructs that mirror Swift's native error handling patterns. Understanding these patterns is crucial for building reliable code generators.

> 📖 **Related**: See <doc:Creating-Macros-with-SyntaxKit> for error handling in macro development contexts.

#### 1. Basic Do-Catch Blocks

```swift
// Simple error handling
Do {
    Call("someRiskyOperation").throwing()
} catch: {
    Catch {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Operation failed: \\(error)"))
        }
    }
}
```

#### 2. Pattern-Based Error Handling

```swift
// Structured error handling with specific error types
Do {
    Call("buyFavoriteSnack") {
        ParameterExp(name: "person", value: Literal.string("Alice"))
        ParameterExp(name: "vendingMachine", value: VariableExp("vendingMachine"))
    }.throwing()
} catch: {
    Catch(EnumCase("invalidSelection")) {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Invalid Selection."))
        }
    }
    Catch(EnumCase("outOfStock")) {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Out of Stock."))
        }
    }
    Catch(EnumCase("insufficientFunds").associatedValue("coinsNeeded", type: "Int")) {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Need \\(coinsNeeded) more coins."))
        }
    }
    Catch {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Unexpected error: \\(error)"))
        }
    }
}
```

#### 3. Typed Throws (Swift 6)

```swift
// Functions with specific error types
Function("summarize") {
    Parameter("ratings", type: "[Int]")
} _: {
    Guard {
        VariableExp("ratings").property("isEmpty").not()
    } else: {
        Throw(EnumCase("noRatings"))
    }
}.throws("StatisticsError")
```

### Debugging Strategies

#### 1. Code Generation Debugging

**Problem**: Generated code doesn't compile or behaves unexpectedly.

**Solution Strategy**:
```swift
// Always inspect generated code during development
let generatedCode = myCodeBlock.generateCode()
print("Generated code:")
print(generatedCode)

// Validate syntax with SwiftSyntax parser
do {
    let sourceFile = try Parser.parse(source: generatedCode)
    print("✅ Syntax is valid")
} catch {
    print("❌ Syntax error: \(error)")
}
```

#### 2. Pattern Matching Issues

**Problem**: Catch patterns don't match expected error types.

**Common Issues**:
- Missing enum case qualifiers
- Incorrect associated value binding
- Pattern order matters

**Solution**:
```swift
// ❌ Problematic pattern
Catch(EnumCase("error")) { ... }

// ✅ Proper enum qualification
Catch(EnumCase("MyError.networkFailure")) { ... }

// ✅ Correct associated value handling
Catch(EnumCase("MyError.validationFailed").associatedValue("field", type: "String")) { ... }
```

#### 3. Result Builder Context Issues

**Problem**: Code blocks don't combine as expected in result builders.

**Debugging Approach**:
```swift
// Break complex builders into smaller components
let errorHandler = Group {
    Catch(EnumCase("specificError")) { ... }
    Catch { ... }
}

Do {
    // main code
} catch: {
    errorHandler
}
```

### Troubleshooting Workflows

#### Workflow 1: Generated Code Validation

1. **Generate and inspect code**:
   ```swift
   let code = myGenerator.generateCode()
   print(code)
   ```

2. **Validate with SwiftSyntax**:
   ```swift
   try Parser.parse(source: code)
   ```

3. **Test compilation**:
   ```bash
   # Save to temporary file and test
   echo "$code" > temp.swift
   swift -parse temp.swift
   ```

#### Workflow 2: Complex Error Pattern Debugging

1. **Isolate the pattern**:
   ```swift
   // Test catch pattern in isolation
   let catchClause = Catch(EnumCase("MyError.specific")) { ... }
   print(catchClause.generateCode())
   ```

2. **Verify enum case structure**:
   ```swift
   // Ensure enum case matches your actual error definition
   enum MyError: Error {
       case specific  // Matches EnumCase("MyError.specific")
       case withData(String)  // Matches EnumCase("MyError.withData").associatedValue("data", type: "String")
   }
   ```

3. **Test full do-catch integration**:
   ```swift
   let fullBlock = Do { ... } catch: { catchClause }
   print(fullBlock.generateCode())
   ```

#### Workflow 3: Async/Await Error Handling

When working with async error handling:

```swift
// Pattern for async throwing functions
Function("fetchData") {
    Parameter("url", type: "URL")
} _: {
    Do {
        Variable(.let, name: "response") {
            Call("URLSession.shared.data") {
                ParameterExp(name: "from", value: VariableExp("url"))
            }
        }.async().throwing()
        Return { VariableExp("response") }
    } catch: {
        Catch(EnumCase("URLError.networkUnavailable")) {
            Throw(EnumCase("APIError.networkError"))
        }
        Catch {
            Throw(EnumCase("APIError.unknownError"))
        }
    }
}.async().throws("APIError")
```

### Common Pitfalls and Solutions

#### 1. Enum Case Qualification

**Problem**: `EnumCase("error")` doesn't match `MyError.error`
**Solution**: Use full qualification: `EnumCase("MyError.error")`

#### 2. Associated Value Binding

**Problem**: Pattern doesn't bind associated values correctly
**Solution**: Use `.associatedValue(name, type)` method:
```swift
// ❌ Won't bind values
Catch(EnumCase("ValidationError.fieldError")) { ... }

// ✅ Properly binds values
Catch(EnumCase("ValidationError.fieldError").associatedValue("field", type: "String")) { ... }
```

#### 3. Catch Order

**Problem**: Generic catch blocks shadow specific patterns
**Solution**: Order catch clauses from specific to general:
```swift
Do { ... } catch: {
    Catch(EnumCase("SpecificError.typeA")) { ... }  // Most specific first
    Catch(EnumCase("SpecificError.typeB")) { ... }
    Catch(EnumCase("GeneralError")) { ... }         // More general
    Catch { ... }                                   // Most general last
}
```

### Testing Error Handling Code

#### Unit Testing Generated Error Handlers

```swift
@Test("Error handling generates correct catch patterns")
func testErrorHandling() throws {
    let errorCode = Do {
        Call("riskyOperation").throwing()
    } catch: {
        Catch(EnumCase("MyError.specific")) {
            Return { Literal.string("handled") }
        }
    }
    
    let generated = errorCode.generateCode()
    #expect(generated.contains("catch MyError.specific"))
}
```

#### Integration Testing

```swift
@Test("Generated error handling compiles and runs")
func testErrorHandlingIntegration() throws {
    // Generate complete error handling code
    let fullExample = generateErrorHandlingExample()
    
    // Verify it compiles
    let syntax = try Parser.parse(source: fullExample.generateCode())
    #expect(syntax.statements.count > 0)
}
```

### Advanced Debugging Techniques

#### 1. SwiftSyntax AST Inspection

When generated code behaves unexpectedly, inspect the underlying AST:

```swift
let codeBlock = Do {
    Call("someFunction").throwing()
} catch: {
    Catch(EnumCase("MyError.specific")) { ... }
}

// Inspect the generated SwiftSyntax AST
let syntax = codeBlock.syntax
print("AST structure: \(syntax.debugDescription)")

// Check specific node types
if let doStmt = syntax.as(DoStmtSyntax.self) {
    print("Catch clauses: \(doStmt.catchClauses?.count ?? 0)")
}
```

#### 2. Incremental Code Building

Build complex error handling incrementally to isolate issues:

```swift
// Start simple
let basicDo = Do {
    Call("operation").throwing()
}

// Add catch clauses one by one
let withCatch = Do {
    Call("operation").throwing()
} catch: {
    Catch { Call("handleError")() }
}

// Verify each step
print(basicDo.generateCode())
print(withCatch.generateCode())
```

#### 3. Pattern Validation Utilities

Create validation helpers for complex patterns:

```swift
extension EnumCase {
    func validatePattern() -> Bool {
        // Verify enum case exists and has correct associated values
        let generated = self.generateCode()
        return !generated.isEmpty && !generated.contains("error")
    }
}

// Use in debugging
let errorCase = EnumCase("MyError.validation").associatedValue("field", type: "String")
assert(errorCase.validatePattern(), "Invalid error pattern")
```

### Debugging Workflow Checklist

When encountering issues with SyntaxKit error handling:

- [ ] **Step 1**: Generate and inspect the raw code output
- [ ] **Step 2**: Validate syntax with SwiftSyntax parser
- [ ] **Step 3**: Test compilation of generated code
- [ ] **Step 4**: Verify enum case names match actual error types
- [ ] **Step 5**: Check associated value types and names
- [ ] **Step 6**: Ensure catch clause order (specific to general)
- [ ] **Step 7**: Test with minimal reproduction case
- [ ] **Step 8**: Inspect underlying SwiftSyntax AST if needed

### Performance Debugging

#### Memory Usage Patterns

Monitor memory usage when generating large error handling structures:

```swift
// Use autoreleasepool for large generation tasks
autoreleasepool {
    let largeErrorHandler = Do {
        // Complex throwing operations
    } catch: {
        // Many catch clauses
        for errorType in errorTypes {
            Catch(EnumCase(errorType)) { ... }
        }
    }
    
    let generated = largeErrorHandler.generateCode()
    // Process generated code
}
```

#### Generation Time Optimization

```swift
// Cache complex error patterns
private static let commonErrorHandler: [CodeBlock] = {
    return [
        Catch(EnumCase("NetworkError.timeout")) { ... },
        Catch(EnumCase("NetworkError.serverError")) { ... },
        Catch { ... }
    ]
}()

// Reuse in multiple contexts
Do {
    // operation code
} catch: {
    commonErrorHandler
}
```

## Integration Patterns

### Project Integration Strategies

#### 1. Xcode Project Integration

**Adding SyntaxKit to iOS/macOS Apps:**

```swift
// In your Xcode project's Package.swift dependencies:
dependencies: [
    .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "1.0.0")
]

// In target dependencies:
.target(
    name: "YourApp",
    dependencies: [
        "SyntaxKit"
    ]
)
```

**Build Phase Integration:**
```bash
# Add run script build phase for automated code generation
#!/bin/bash
set -e

# Generate API endpoints from configuration
swift Scripts/generate-endpoints.swift api-config.json

# Generate model types from schema
swift Scripts/generate-models.swift schema.json

echo "✅ Code generation complete"
```

**Best Practices:**
- Run generators before compilation in build phases
- Store generated code in predictable locations
- Add generated files to `.gitignore` if they should be build-time only
- Include source configuration files in version control

#### 2. Swift Package Manager Integration

**Package.swift Configuration:**

```swift
// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MyProject",
    platforms: [
        .macOS(.v13), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)
    ],
    products: [
        .library(name: "MyProject", targets: ["MyProject"]),
        .executable(name: "code-generator", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "1.0.0")
    ],
    targets: [
        // Main library target
        .target(
            name: "MyProject",
            dependencies: []
        ),
        
        // Code generator executable
        .executableTarget(
            name: "CodeGenerator",
            dependencies: ["SyntaxKit"],
            path: "Tools/CodeGenerator"
        ),
        
        // Tests
        .testTarget(
            name: "MyProjectTests",
            dependencies: ["MyProject"]
        )
    ]
)
```

**Directory Structure:**
```
MyProject/
├── Package.swift
├── Sources/
│   └── MyProject/
│       ├── Generated/          # Auto-generated code
│       │   ├── APIEndpoints.swift
│       │   └── Models.swift
│       └── Core/               # Hand-written code
│           └── MyProject.swift
├── Tools/
│   └── CodeGenerator/
│       ├── main.swift
│       └── Generators/
│           ├── EndpointGenerator.swift
│           └── ModelGenerator.swift
└── Config/
    ├── api-endpoints.json
    └── model-schema.json
```

> 📋 **Real Example**: The <doc:EnumGenerator> tutorial demonstrates this exact pattern with a complete working example.

#### 3. Build System Integration

**Makefile Integration:**
```makefile
.PHONY: generate build test

generate:
	@echo "🔧 Generating code..."
	@swift run code-generator
	@echo "✅ Code generation complete"

build: generate
	swift build

test: generate
	swift test

clean:
	swift package clean
	rm -rf Sources/*/Generated/*
```

**Package.swift Plugin (Advanced):**
```swift
// For automated generation during builds
.plugin(
    name: "CodeGeneration",
    capability: .buildTool(),
    dependencies: ["SyntaxKit"]
)
```

### CI/CD Integration

#### GitHub Actions Integration

```yaml
name: Build and Test with Code Generation

on: [push, pull_request]

jobs:
  generate-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate Code
        run: |
          swift run code-generator config/api-schema.json
          
      - name: Verify Generated Code
        run: |
          # Ensure generated code compiles
          swift build
          
      - name: Run Tests
        run: |
          swift test --enable-code-coverage
          
      - name: Commit Generated Code (if needed)
        run: |
          if [[ -n $(git diff --exit-code Sources/*/Generated/) ]]; then
            git config user.name "GitHub Actions"
            git config user.email "actions@github.com"
            git add Sources/*/Generated/
            git commit -m "Update generated code [skip ci]"
            git push
          fi
```

#### Continuous Integration Best Practices

**1. Generation Validation:**
```bash
#!/bin/bash
# Scripts/validate-generation.sh

# Generate fresh code
swift run code-generator

# Check if generated code compiles
if ! swift build; then
    echo "❌ Generated code does not compile"
    exit 1
fi

# Verify no unexpected changes
if git diff --quiet Sources/*/Generated/; then
    echo "✅ Generated code is up to date"
else
    echo "⚠️  Generated code has changes - review required"
    git diff Sources/*/Generated/
fi
```

**2. Multi-Platform Testing:**
```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest]
    swift: ['6.1', '6.2']
    
steps:
  - name: Test Code Generation
    run: |
      swift run code-generator --validate
      swift test --filter GenerationTests
```

### Team Workflow Patterns

#### 1. Separation of Concerns

**Structure for Team Development:**
```
project/
├── Sources/
│   ├── Core/              # Hand-written business logic
│   └── Generated/         # SyntaxKit-generated code
├── Tools/
│   ├── Generators/        # SyntaxKit generator scripts
│   └── Schemas/          # Configuration files
└── Scripts/
    ├── generate.sh       # Main generation script
    └── validate.sh       # Validation script
```

#### 2. Code Review Workflows

**For Generated Code:**
- Review generator logic, not generated output
- Validate configuration files thoroughly
- Test generator with edge cases
- Automate generation in CI/CD

**Review Checklist:**
- [ ] Generator logic is clear and maintainable
- [ ] Configuration schema is validated
- [ ] Generated code compiles and passes tests
- [ ] Integration tests cover generated functionality
- [ ] Documentation explains generation process

#### 3. Version Control Strategies

**Option A: Commit Generated Code**
```gitignore
# Don't ignore generated code
# Sources/*/Generated/
```
**Pros:** Easier debugging, clear diffs
**Cons:** Large commits, merge conflicts

**Option B: Generate at Build Time**
```gitignore
# Ignore generated code
Sources/*/Generated/
```
**Pros:** Clean commits, no merge conflicts
**Cons:** Requires build-time generation setup

### Common Integration Pitfalls

#### 1. Dependency Management

**Problem:** SwiftSyntax version conflicts
**Solution:** Pin specific versions in Package.swift

```swift
.package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "601.0.1")
```

#### 2. Build Order Issues

**Problem:** Generated code needed before compilation
**Solution:** Use build phases or pre-build scripts

```bash
# pre-build.sh
if [ ! -f "Sources/Generated/APIEndpoints.swift" ]; then
    swift run code-generator
fi
```

#### 3. Path Resolution

**Problem:** Generator can't find configuration files
**Solution:** Use absolute paths or proper working directories

```swift
// In generator code
let configURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("config.json")
```

## Code Organization Patterns

### Structuring SyntaxKit Projects

#### 1. Generator Organization

**Recommended Structure:**
```
Tools/
├── Generators/
│   ├── Base/
│   │   ├── BaseGenerator.swift      # Common generator functionality
│   │   └── ConfigurationLoader.swift # Shared config loading
│   ├── API/
│   │   ├── EndpointGenerator.swift  # API endpoint generation
│   │   └── ModelGenerator.swift     # Data model generation
│   └── UI/
│       ├── ViewGenerator.swift      # SwiftUI view generation
│       └── ComponentGenerator.swift # Reusable component generation
├── Schemas/
│   ├── api-schema.json
│   ├── model-schema.json
│   └── ui-components.json
└── main.swift                       # CLI entry point
```

#### 2. Modular Generation

**Base Generator Pattern:**
```swift
// BaseGenerator.swift
protocol Generator {
    associatedtype Configuration: Codable
    associatedtype Output: CodeBlock
    
    func generate(from config: Configuration) -> Output
    func validate(config: Configuration) throws
}

class BaseGenerator<Config: Codable, Output: CodeBlock>: Generator {
    func loadConfiguration(from url: URL) throws -> Config {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Config.self, from: data)
    }
    
    func generate(from config: Config) -> Output {
        fatalError("Override in subclass")
    }
    
    func validate(config: Config) throws {
        // Common validation logic
    }
}
```

**Specific Generator Implementation:**
```swift
// EndpointGenerator.swift
struct APIConfiguration: Codable {
    let version: String
    let baseURL: String
    let endpoints: [Endpoint]
}

class EndpointGenerator: BaseGenerator<APIConfiguration, Enum> {
    override func generate(from config: APIConfiguration) -> Enum {
        return Enum("APIEndpoint") {
            for endpoint in config.endpoints {
                EnumCase(endpoint.name)
                    .equals(Literal.string("\(config.baseURL)/\(config.version)/\(endpoint.path)"))
            }
        }
        .inherits("String")
        .access(.public)
    }
}
```

### Testing Generated Code

#### 1. Generator Unit Tests

```swift
@Test("API generator creates correct endpoints")
func testAPIGeneration() throws {
    let config = APIConfiguration(
        version: "v2",
        baseURL: "https://api.example.com",
        endpoints: [
            Endpoint(name: "users", path: "users"),
            Endpoint(name: "posts", path: "posts")
        ]
    )
    
    let generator = EndpointGenerator()
    let enum = generator.generate(from: config)
    let code = enum.generateCode()
    
    #expect(code.contains("case users = \"https://api.example.com/v2/users\""))
    #expect(code.contains("case posts = \"https://api.example.com/v2/posts\""))
}
```

#### 2. Integration Tests

```swift
@Test("Generated code compiles and runs correctly")
func testGeneratedCodeIntegration() throws {
    // Generate complete module
    let generator = CompleteModuleGenerator()
    let module = generator.generateModule(from: testConfig)
    
    // Write to temporary directory
    let tempDir = FileManager.default.temporaryDirectory
    let moduleFile = tempDir.appendingPathComponent("Generated.swift")
    try module.generateCode().write(to: moduleFile, atomically: true, encoding: .utf8)
    
    // Attempt compilation
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["-parse", moduleFile.path]
    
    try process.run()
    process.waitUntilExit()
    
    #expect(process.terminationStatus == 0, "Generated code should compile")
}
```

## Testing Strategies for Generated Code

### Core Testing Approaches

#### 1. String-Based Comparison Testing

**Basic Pattern:**
```swift
@Test("Function generates correct syntax")
func testFunctionGeneration() {
    let function = Function("greet") {
        Parameter("name", type: "String")
    } _: {
        Return { Literal.string("Hello, \\(name)!") }
    }
    
    let generated = function.generateCode()
    let expected = """
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
        """
    
    #expect(generated.normalize() == expected.normalize())
}
```

**Advanced Normalization:**
```swift
// Use specialized normalization for different contexts
#expect(generated.normalize(options: .swiftUI) == expected.normalize(options: .swiftUI))

// Structural comparison ignoring all formatting
#expect(generated.normalizeStructural() == expected.normalizeStructural())

// Flexible comparison for resilient tests
#expect(generated.normalizeFlexible() == expected.normalizeFlexible())
```

#### 2. Syntax-Based Validation

**SwiftSyntax Parser Validation:**
```swift
@Test("Generated code has valid syntax")
func testSyntaxValidity() throws {
    let codeBlock = Struct("TestStruct") {
        Variable(.let, name: "value", type: "String")
    }
    
    let generated = codeBlock.generateCode()
    
    // Parse with SwiftSyntax to validate syntax
    let sourceFile = try Parser.parse(source: generated)
    #expect(sourceFile.statements.count > 0)
    
    // Verify specific syntax elements
    let structDecl = sourceFile.statements.first?.item.as(DeclSyntax.self)?.as(StructDeclSyntax.self)
    #expect(structDecl?.name.text == "TestStruct")
}
```

#### 3. Integration Testing

**Compilation Testing:**
```swift
@Test("Generated code compiles successfully")
func testCompilation() throws {
    let module = generateCompleteModule()
    let tempFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("Generated.swift")
    
    try module.generateCode().write(to: tempFile, atomically: true, encoding: .utf8)
    
    // Test compilation
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["-parse", tempFile.path]
    
    try process.run()
    process.waitUntilExit()
    
    #expect(process.terminationStatus == 0, "Generated code should compile")
    
    // Clean up
    try FileManager.default.removeItem(at: tempFile)
}
```

#### 4. Behavioral Testing

**Runtime Behavior Validation:**
```swift
@Test("Generated enum works correctly at runtime")
func testGeneratedEnumBehavior() throws {
    let enumGenerator = EnumGenerator()
    let generatedEnum = enumGenerator.generateAPIEndpoints(from: testConfig)
    
    // Write to executable Swift script
    let script = """
        \(generatedEnum.generateCode())
        
        // Test runtime behavior
        print(APIEndpoint.users.rawValue)
        print(APIEndpoint.posts.rawValue)
        """
    
    let result = try executeSwiftScript(script)
    #expect(result.contains("https://api.example.com/v2/users"))
    #expect(result.contains("https://api.example.com/v2/posts"))
}
```

### Test Organization Patterns

#### 1. Test Suite Structure

**Recommended Organization:**
```
Tests/
├── GeneratorTests/
│   ├── Unit/
│   │   ├── APIGeneratorTests.swift      # Individual generator testing
│   │   ├── ModelGeneratorTests.swift
│   │   └── ValidationTests.swift        # Input validation testing
│   ├── Integration/
│   │   ├── EndToEndTests.swift         # Complete generation workflows
│   │   ├── CompilationTests.swift      # Generated code compilation
│   │   └── RuntimeTests.swift          # Generated code execution
│   └── Fixtures/
│       ├── test-config.json
│       ├── expected-output.swift
│       └── TestUtilities.swift
```

#### 2. Test Data Management

**Configuration-Driven Testing:**
```swift
struct TestConfiguration {
    let name: String
    let input: String
    let expectedOutput: String
    let validationRules: [ValidationRule]
}

class GeneratorTestSuite {
    static let testCases: [TestConfiguration] = [
        TestConfiguration(
            name: "Basic API Endpoints",
            input: "test-configs/basic-api.json",
            expectedOutput: "expected-outputs/basic-api.swift",
            validationRules: [.compilesSuccessfully, .matchesExpectedStructure]
        ),
        // More test cases...
    ]
    
    @Test("Generator handles all test configurations", arguments: testCases)
    func testGeneratorWithConfiguration(config: TestConfiguration) throws {
        let generator = APIGenerator()
        let input = try loadTestInput(config.input)
        let generated = generator.generate(from: input)
        
        for rule in config.validationRules {
            try rule.validate(generated)
        }
    }
}
```

### Quality Assurance Strategies

#### 1. Code Coverage for Generators

**Generator Path Coverage:**
```swift
@Test("Generator covers all configuration paths")
func testGeneratorCoverage() throws {
    let configurations = [
        basicConfig,
        configWithOptionalFields,
        configWithArrays,
        configWithNestedObjects,
        edgeCaseConfig
    ]
    
    for config in configurations {
        let generator = ModelGenerator()
        let result = generator.generate(from: config)
        
        // Verify all config fields are used
        let generated = result.generateCode()
        verifyAllFieldsUsed(config: config, in: generated)
    }
}
```

#### 2. Regression Testing

**Golden Master Testing:**
```swift
@Test("Generated output matches golden master")
func testGoldenMaster() throws {
    let generator = CompleteGenerator()
    let generated = generator.generate(from: standardConfig)
    
    let goldenMasterPath = Bundle.module.path(forResource: "golden-master", ofType: "swift")!
    let expectedOutput = try String(contentsOfFile: goldenMasterPath)
    
    #expect(generated.generateCode().normalize() == expectedOutput.normalize())
}

// Helper for updating golden masters during development
func updateGoldenMaster() throws {
    let generator = CompleteGenerator()
    let generated = generator.generate(from: standardConfig)
    
    let outputPath = "Tests/GoldenMasters/golden-master.swift"
    try generated.generateCode().write(toFile: outputPath, atomically: true, encoding: .utf8)
}
```

#### 3. Property-Based Testing

**Fuzzing Configuration Inputs:**
```swift
@Test("Generator handles arbitrary valid configurations")
func testPropertyBasedGeneration() throws {
    // Generate random valid configurations
    for _ in 0..<100 {
        let randomConfig = generateRandomValidConfig()
        let generator = APIGenerator()
        
        do {
            let result = generator.generate(from: randomConfig)
            let generated = result.generateCode()
            
            // Basic invariants that should always hold
            #expect(!generated.isEmpty)
            #expect(try Parser.parse(source: generated).statements.count > 0)
            
        } catch {
            // If generation fails, ensure it's for a valid reason
            #expect(error is ConfigurationValidationError)
        }
    }
}
```

### Automated Testing Workflows

#### 1. Continuous Validation

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🧪 Running generator tests..."
swift test --filter GeneratorTests

echo "🔧 Validating generated code..."
swift run validate-generators

echo "✅ All checks passed"
```

#### 2. CI/CD Test Pipeline

**GitHub Actions Testing:**
```yaml
name: Generator Testing Pipeline

on: [push, pull_request]

jobs:
  test-generators:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Unit Tests
        run: swift test --filter "GeneratorTests"
        
      - name: Integration Tests  
        run: swift test --filter "IntegrationTests"
        
      - name: Generated Code Compilation
        run: |
          # Generate test code
          swift run test-generator
          
          # Verify it compiles
          swift build --target GeneratedTestCode
          
      - name: Runtime Validation
        run: |
          # Execute generated code and verify output
          swift run generated-test-executable > output.txt
          diff output.txt expected-output.txt
```

#### 3. Performance Testing

**Generation Performance Benchmarks:**
```swift
@Test("Generator performance stays within bounds")
func testGenerationPerformance() throws {
    let largeConfig = createLargeConfiguration(1000) // 1000 endpoints
    let generator = APIGenerator()
    
    let startTime = Date()
    let result = generator.generate(from: largeConfig)
    let _ = result.generateCode()
    let duration = Date().timeIntervalSince(startTime)
    
    // Should generate 1000 endpoints in under 5 seconds
    #expect(duration < 5.0, "Generation took \(duration)s, expected < 5s")
}
```

### Testing Anti-Patterns to Avoid

#### 1. Over-Specific String Matching

```swift
// ❌ Brittle - breaks with formatting changes
#expect(generated == "func test() {\n  return \"value\"\n}")

// ✅ Robust - focuses on structure
#expect(generated.normalize() == expected.normalize())
```

#### 2. Testing Implementation Details

```swift
// ❌ Testing internal syntax tree details
#expect(syntax.as(FunctionDeclSyntax.self)?.signature.parameterClause.parameters.count == 2)

// ✅ Testing generated code behavior
let generated = function.generateCode()
#expect(generated.contains("func test(param1: String, param2: Int)"))
```

#### 3. Ignoring Edge Cases

```swift
// ❌ Only testing happy path
@Test func testBasicGeneration() { ... }

// ✅ Comprehensive edge case coverage
@Test func testEmptyConfiguration() { ... }
@Test func testMalformedConfiguration() { ... }
@Test func testMaximumSizeConfiguration() { ... }
@Test func testSpecialCharactersInNames() { ... }
```

## Performance Optimization

### Memory Management

**Use autoreleasepool for Large Generations:**
```swift
autoreleasepool {
    let largeCodeGenerator = generateManyClasses(count: 1000)
    let output = largeCodeGenerator.generateCode()
    try output.write(to: outputURL, atomically: true, encoding: .utf8)
}
```

**Lazy Generation Patterns:**
```swift
// Generate on-demand rather than upfront
struct LazyAPIGenerator {
    private let config: APIConfiguration
    
    func generateEndpoint(_ name: String) -> Function {
        // Generate only when needed
        return Function(name) { /* ... */ }
    }
}
```

### Generation Time Optimization

**Cache Common Patterns:**
```swift
private static let commonImports: [Import] = [
    Import("Foundation"),
    Import("Combine"),
    Import("SwiftUI")
]

// Reuse across generators
func generateModule() -> Group {
    Group {
        commonImports
        // Rest of module
    }
}
```

**Batch Operations:**
```swift
// Generate multiple related structures together
let apiModule = Group {
    generateAllEndpoints(from: config)
    generateAllModels(from: config) 
    generateAllErrors(from: config)
}
```

## Common Anti-Patterns

### 1. Over-Engineering Simple Cases

```swift
// ❌ Over-engineered for simple constant
let complexGenerator = Struct("Constants") {
    Variable(.static, name: "apiURL", equals: Literal.string(url))
}

// ✅ Just use regular Swift for simple constants
struct Constants {
    static let apiURL = "https://api.example.com"
}
```

### 2. Replacing Hand-Written Code Unnecessarily

**When NOT to use SyntaxKit:**
- Simple, stable data structures
- One-time code that won't change
- Performance-critical paths
- Code that's easier to write by hand

### 3. Ignoring SwiftSyntax Best Practices

```swift
// ❌ Creating inefficient AST structures
let inefficient = Group {
    for i in 0..<1000 {
        Variable(.let, name: "var\(i)", equals: Literal.integer(i))
    }
}

// ✅ Use batch operations when possible
let efficient = Group {
    createVariableBatch(count: 1000)
}
```

## Migration from Manual SwiftSyntax

### 1. Identify Conversion Opportunities

**Before (Manual SwiftSyntax):**
```swift
let functionDecl = FunctionDeclSyntax(
    name: .identifier("test"),
    signature: FunctionSignatureSyntax(
        parameterClause: ParameterClauseSyntax(
            parameters: FunctionParameterListSyntax([
                FunctionParameterSyntax(
                    firstName: .identifier("param"),
                    type: IdentifierTypeSyntax(name: .identifier("String"))
                )
            ])
        )
    ),
    body: CodeBlockSyntax(statements: CodeBlockItemListSyntax([]))
)
```

**After (SyntaxKit):**
```swift
let function = Function("test") {
    Parameter("param", type: "String")
} _: {
    // Body content
}
```

### 2. Migration Strategy

1. **Identify Repetitive Patterns**: Look for repeated AST construction
2. **Start Small**: Migrate simple structures first  
3. **Test Thoroughly**: Ensure generated code matches original
4. **Refactor Gradually**: Replace sections incrementally
5. **Document Changes**: Update team knowledge

## Summary

SyntaxKit transforms complex Swift code generation from tedious AST manipulation into intuitive, maintainable declarations. By following these best practices, you'll build robust code generators that are:

- **Reliable**: Comprehensive error handling and testing
- **Maintainable**: Clean organization and clear patterns  
- **Integrated**: Seamless project and CI/CD integration
- **Performant**: Optimized generation and memory usage

**Key Takeaways:**
- Use SyntaxKit for programmatic code generation, not application logic
- Implement comprehensive testing at multiple levels
- Structure generators for maintainability and reusability
- Integrate generation into your development workflow
- Debug systematically using provided tools and techniques

> 📖 **Next Steps**: 
> - **Macro Development**: <doc:Creating-Macros-with-SyntaxKit> tutorial
> - **Code Generation**: <doc:EnumGenerator> practical example
> - **Quick Start**: <doc:Quick-Start-Guide> for immediate hands-on experience