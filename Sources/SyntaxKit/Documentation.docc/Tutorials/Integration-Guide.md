# Integration Guide

Learn how to integrate SyntaxKit into existing Swift projects with real-world patterns and team workflows.

## Overview

This tutorial provides practical guidance for adding SyntaxKit to existing Swift projects, including build system integration, CI/CD setup, and team collaboration patterns. Whether you're working on an iOS app, server-side Swift project, or command-line tool, this guide shows you how to integrate SyntaxKit effectively.

**Time to complete**: 15 minutes  
**Prerequisites**: Existing Swift project, basic git knowledge

## Adding SyntaxKit to Existing Projects

### Xcode Project Integration

#### Step 1: Add SyntaxKit via Swift Package Manager

1. **Open your existing Xcode project**
2. **Add Package Dependency**: File → Add Package Dependencies...
3. **Enter Repository URL**: `https://github.com/brightdigit/SyntaxKit.git`
4. **Choose Version Rule**: "Up to Next Major Version" starting from 1.0.0
5. **Select Target**: Choose the target(s) where you'll use SyntaxKit
6. **Add Package**: Click "Add Package" to complete the integration

#### Step 2: Verify Integration

Create a simple test file to verify SyntaxKit is properly integrated:

```swift
// TestSyntaxKit.swift
import SyntaxKit

func testSyntaxKitIntegration() {
    let simpleStruct = Struct("TestStruct") {
        Property("name", type: "String")
        Property("id", type: "Int")
    }
    
    print(simpleStruct.formatted().description)
}
```

#### Step 3: Configure Build Settings (Optional)

For optimal performance in large projects:

1. **Build Settings** → **Other Swift Flags**
2. Add `-Xfrontend -warn-long-function-bodies=100` for performance monitoring
3. Consider enabling **Whole Module Optimization** for release builds

### Swift Package Manager Integration

#### Adding to Package.swift

For existing Swift packages, update your `Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "YourExistingPackage",
    platforms: [
        .macOS(.v13), .iOS(.v13), .watchOS(.v6), .tvOS(.v13), .visionOS(.v1)
    ],
    products: [
        .library(name: "YourLibrary", targets: ["YourLibrary"]),
        // Add executable if you're creating code generation tools
        .executable(name: "YourGenerator", targets: ["YourGenerator"])
    ],
    dependencies: [
        // Your existing dependencies
        .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourLibrary",
            dependencies: [
                "SyntaxKit" // Add to targets that need code generation
            ]
        ),
        .executableTarget(
            name: "YourGenerator",
            dependencies: [
                "SyntaxKit",
                "YourLibrary"
            ]
        ),
        .testTarget(
            name: "YourLibraryTests",
            dependencies: ["YourLibrary"]
        )
    ]
)
```

#### Integration Patterns for Different Package Types

**Library Package Integration**:
```swift
// In your library target
import SyntaxKit

public protocol CodeGeneratable {
    func generateSwiftCode() -> String
}

public extension CodeGeneratable {
    func generateSwiftCode() -> String {
        // Use SyntaxKit to generate code from your data models
    }
}
```

**Command-Line Tool Integration**:
```swift
// In your executable target
import ArgumentParser
import SyntaxKit

@main
struct CodeGenerator: ParsableCommand {
    @Option(help: "Input configuration file")
    var input: String
    
    @Option(help: "Output Swift file")
    var output: String
    
    func run() throws {
        // Read input configuration
        // Use SyntaxKit to generate Swift code
        // Write to output file
    }
}
```

## Build System Integration

### Xcode Build Phases

#### Creating a Code Generation Build Phase

1. **Select Target** → **Build Phases** → **+** → **New Run Script Phase**
2. **Name**: "Generate Swift Code"
3. **Shell**: `/bin/sh`
4. **Script**:

```bash
#!/bin/sh

# Path to your code generator executable
GENERATOR="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}Generator"

# Input and output paths
INPUT_DIR="${SRCROOT}/Configuration"
OUTPUT_DIR="${SRCROOT}/Generated"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Run code generation
if [ -f "${GENERATOR}" ]; then
    "${GENERATOR}" --input "${INPUT_DIR}/config.json" --output "${OUTPUT_DIR}/GeneratedCode.swift"
else
    echo "warning: Code generator not found at ${GENERATOR}"
fi
```

5. **Input Files**: Add input configuration files
6. **Output Files**: Add generated Swift files
7. **Move Phase**: Position before "Compile Sources"

#### Input/Output File Configuration

For optimal build performance, configure input and output files:

**Input Files**:
- `$(SRCROOT)/Configuration/config.json`
- `$(SRCROOT)/Templates/*.template`

**Output Files**:
- `$(SRCROOT)/Generated/Models.swift`
- `$(SRCROOT)/Generated/Enums.swift`

This ensures Xcode only runs code generation when input files change.

### Swift Package Manager Plugins

#### Creating a Build Tool Plugin

Create `Plugins/CodeGeneratorPlugin/plugin.swift`:

```swift
import PackagePlugin

@main
struct CodeGeneratorPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        
        let configFiles = target.sourceFiles.filter { $0.path.extension == "json" }
        
        return configFiles.map { configFile in
            let outputPath = context.pluginWorkDirectory
                .appending(configFile.path.stem + ".swift")
            
            return .buildCommand(
                displayName: "Generating Swift code from \(configFile.path.lastComponent)",
                executable: try context.tool(named: "YourGenerator").path,
                arguments: [
                    "--input", configFile.path.string,
                    "--output", outputPath.string
                ],
                inputFiles: [configFile.path],
                outputFiles: [outputPath]
            )
        }
    }
}
```

Add to your `Package.swift`:

```swift
let package = Package(
    // ... existing configuration
    products: [
        .plugin(name: "CodeGeneratorPlugin", targets: ["CodeGeneratorPlugin"])
    ],
    targets: [
        .plugin(
            name: "CodeGeneratorPlugin",
            capability: .buildTool(),
            dependencies: ["YourGenerator"]
        )
    ]
)
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/code-generation.yml`:

```yaml
name: Code Generation

on:
  push:
    paths:
      - 'Configuration/**'
      - 'Templates/**'
  pull_request:
    paths:
      - 'Configuration/**'
      - 'Templates/**'

jobs:
  generate-code:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v2
      with:
        swift-version: '6.1'
    
    - name: Cache Swift packages
      uses: actions/cache@v4
      with:
        path: |
          .build
          ~/Library/Caches/org.swift.swiftpm
        key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift') }}
        restore-keys: |
          ${{ runner.os }}-spm-
    
    - name: Build code generator
      run: swift build --product YourGenerator
    
    - name: Generate Swift code
      run: |
        mkdir -p Generated
        .build/debug/YourGenerator \
          --input Configuration/config.json \
          --output Generated/GeneratedCode.swift
    
    - name: Verify generated code compiles
      run: swift build
    
    - name: Commit generated code (if changed)
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add Generated/
        git diff --staged --quiet || git commit -m "Update generated code"
        git push
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - generate
  - test

variables:
  SWIFT_VERSION: "6.1"

generate_code:
  stage: generate
  image: swift:$SWIFT_VERSION
  script:
    - swift build --product YourGenerator
    - mkdir -p Generated
    - .build/debug/YourGenerator --input Configuration/config.json --output Generated/
    - git add Generated/
    - |
      if ! git diff --staged --quiet; then
        git commit -m "Update generated code [skip ci]"
        git push origin $CI_COMMIT_REF_NAME
      fi
  artifacts:
    paths:
      - Generated/
    expire_in: 1 hour
  only:
    changes:
      - Configuration/**/*
      - Templates/**/*

test_generated:
  stage: test
  image: swift:$SWIFT_VERSION
  script:
    - swift test
  dependencies:
    - generate_code
```

### Caching Strategies

#### SPM Dependencies
```yaml
# GitHub Actions
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      .build
      ~/Library/Caches/org.swift.swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift') }}
```

#### Generated Code Artifacts
```yaml
# Store generated code between jobs
- name: Upload generated code
  uses: actions/upload-artifact@v4
  with:
    name: generated-swift-code
    path: Generated/
    retention-days: 1
```

## Team Workflow Patterns

### Code Review Best Practices

#### Separating Generated and Hand-Written Code

**Directory Structure**:
```
YourProject/
├── Sources/
│   ├── YourProject/           # Hand-written code
│   │   ├── Models/
│   │   ├── Views/
│   │   └── Controllers/
│   └── Generated/             # Generated code (separate target)
│       ├── APIModels.swift
│       ├── DatabaseEnums.swift
│       └── ConfigTypes.swift
├── Configuration/             # Input files for generation
│   ├── api-spec.json
│   └── database-schema.json
└── Templates/                 # Code generation templates
    ├── model.template
    └── enum.template
```

#### Git Workflow Recommendations

1. **Separate commits for configuration vs generated code**:
   ```bash
   # First commit: configuration changes
   git add Configuration/
   git commit -m "Update API configuration for new endpoints"
   
   # Second commit: generated code changes
   git add Generated/
   git commit -m "Regenerate API models from updated configuration"
   ```

2. **Use `.gitattributes` for generated files**:
   ```gitattributes
   # Mark generated files
   Generated/*.swift linguist-generated=true
   Generated/*.swift diff=swift
   ```

3. **Pre-commit hooks for validation**:
   ```bash
   #!/bin/sh
   # .git/hooks/pre-commit
   
   # Check if configuration files changed
   if git diff --cached --name-only | grep -q "Configuration/"; then
       echo "Configuration changed, regenerating code..."
       swift run YourGenerator
       
       # Add any newly generated files
       git add Generated/
   fi
   ```

### Versioning Strategies

#### Semantic Versioning for Generated Code

Track configuration and generated code versions separately:

```swift
// In your configuration
struct CodeGenerationConfig: Codable {
    let version: String = "1.2.0"
    let generatedAt: Date = Date()
    let configHash: String
    
    // Your configuration data
}
```

#### Incremental Generation

Design generators to support incremental updates:

```swift
func generateCode(from config: Config, existingCode: String?) -> String {
    // Check if regeneration is needed
    guard shouldRegenerate(config, existingCode) else {
        return existingCode ?? ""
    }
    
    // Generate only changed portions
    return incrementalGenerate(config, existingCode)
}
```

### Conflict Resolution

#### Handling Merge Conflicts in Generated Code

1. **Never manually edit generated files**
2. **Resolve conflicts in configuration files**
3. **Regenerate after merging**:

```bash
# After resolving configuration conflicts
git merge feature-branch
swift run YourGenerator  # Regenerate from merged config
git add Generated/
git commit -m "Regenerate code after merge"
```

#### Branch Protection Rules

Configure GitHub/GitLab to require:
- Generated code matches configuration
- All tests pass after code generation
- No manual edits to generated files

## Migration from Existing Solutions

### From Sourcery

Sourcery uses templates, SyntaxKit uses declarative Swift code:

**Before (Sourcery template)**:
```stencil
{% for enum in types.enums %}
enum {{ enum.name }}: String {
    {% for case in enum.cases %}
    case {{ case.name }} = "{{ case.rawValue }}"
    {% endfor %}
}
{% endfor %}
```

**After (SyntaxKit)**:
```swift
func generateEnum(from sourceEnum: SourceEnum) -> Enum {
    Enum(sourceEnum.name, conformsTo: ["String"]) {
        for enumCase in sourceEnum.cases {
            Case(enumCase.name, rawValue: enumCase.rawValue)
        }
    }
}
```

#### Migration Steps

1. **Audit existing templates**: Catalog what Sourcery generates
2. **Convert incrementally**: Replace one template at a time
3. **Validate output**: Ensure generated code matches exactly
4. **Update build process**: Replace Sourcery build phases

### From SwiftGen

SwiftGen focuses on assets, SyntaxKit handles arbitrary Swift code:

**SwiftGen strengths**: Asset generation (colors, images, strings)  
**SyntaxKit strengths**: Complex Swift type generation, macro development

**Hybrid approach**: Use SwiftGen for assets, SyntaxKit for type generation:

```swift
// Use SyntaxKit to generate models that work with SwiftGen assets
let viewModel = Struct("AssetViewModel") {
    Property("backgroundColor", type: "UIColor", defaultValue: "Asset.Colors.primary")
    Property("iconImage", type: "UIImage?", defaultValue: "Asset.Images.icon")
}
```

### From Custom Scripts

Replace shell scripts and Ruby generators with type-safe Swift:

**Before (shell script)**:
```bash
#!/bin/bash
echo "enum APIEndpoint: String {" > Generated/Endpoints.swift
cat api-config.json | jq -r '.endpoints[] | "    case \(.name) = \"\(.path)\""' >> Generated/Endpoints.swift
echo "}" >> Generated/Endpoints.swift
```

**After (SyntaxKit)**:
```swift
import SyntaxKit
import Foundation

func generateEndpoints(from configPath: String) throws -> String {
    let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
    let config = try JSONDecoder().decode(APIConfig.self, from: data)
    
    let endpointEnum = Enum("APIEndpoint", conformsTo: ["String"]) {
        for endpoint in config.endpoints {
            Case(endpoint.name, rawValue: endpoint.path)
        }
    }
    
    return endpointEnum.formatted().description
}
```

## Framework Integration Examples

### SwiftUI Integration

Generate SwiftUI view models and data structures:

```swift
import SyntaxKit

func generateSwiftUIModels(from schema: APISchema) -> String {
    let models = schema.models.map { model in
        Struct("\(model.name)ViewModel", conformsTo: ["ObservableObject"]) {
            // Generate @Published properties
            for property in model.properties {
                Property(property.name, 
                        type: property.swiftType,
                        modifiers: [.published])
            }
            
            // Generate update methods
            Function("update", parameters: [
                Parameter("from", type: model.name)
            ]) {
                for property in model.properties {
                    Assignment(property.name, value: "from.\(property.name)")
                }
            }
        }
    }
    
    return models.map(\.formatted().description).joined(separator: "\n\n")
}
```

### Vapor Integration

Generate Vapor route handlers and models:

```swift
import SyntaxKit

func generateVaporRoutes(from apiSpec: OpenAPISpec) -> String {
    let routeExtension = Extension("Application") {
        Function("configureAPIRoutes", modifiers: [.private]) {
            for route in apiSpec.routes {
                // Generate route registration
                MethodCall("app", method: route.httpMethod.lowercased(), arguments: [
                    Argument(route.path),
                    Argument("use: \(route.handlerName)")
                ])
            }
        }
    }
    
    return routeExtension.formatted().description
}
```

### Core Data Integration

Generate Core Data model extensions:

```swift
import SyntaxKit

func generateCoreDataExtensions(from entities: [CoreDataEntity]) -> String {
    let extensions = entities.map { entity in
        Extension(entity.name) {
            // Generate convenience initializers
            Function("init", parameters: entity.properties.map { property in
                Parameter(property.name, type: property.type)
            }) {
                for property in entity.properties {
                    Assignment("self.\(property.name)", value: property.name)
                }
            }
            
            // Generate computed properties for relationships
            for relationship in entity.relationships {
                ComputedProperty(relationship.name, type: relationship.destinationType) {
                    Return(relationship.coreDataAccessor)
                }
            }
        }
    }
    
    return extensions.map(\.formatted().description).joined(separator: "\n\n")
}
```

## Deployment Considerations

### Distribution Strategies

#### Embedded Code Generation

For tools that include SyntaxKit:

```swift
// Package.swift for tools using SyntaxKit
.product(
    name: "YourCodeGenerator",
    targets: ["YourCodeGenerator"]
),
.executableTarget(
    name: "YourCodeGenerator",
    dependencies: ["SyntaxKit"],
    resources: [
        .copy("Templates/"),  // Include templates as resources
        .copy("Schemas/")     // Include schemas as resources
    ]
)
```

#### Server-Side Code Generation

For web services that generate Swift code:

```swift
import Vapor
import SyntaxKit

func setupCodeGenerationRoutes(_ app: Application) {
    app.post("generate", "swift") { req -> Response in
        let config = try req.content.decode(GenerationConfig.self)
        
        let swiftCode = generateSwiftCode(from: config)
        
        return Response(
            status: .ok,
            headers: ["Content-Type": "text/plain"],
            body: .init(string: swiftCode)
        )
    }
}
```

### Performance Considerations

#### Memory Management for Large Generation

```swift
import SyntaxKit

func generateLargeCodebase(entities: [Entity]) -> String {
    // Process in batches to manage memory
    let batchSize = 100
    var results: [String] = []
    
    for batch in entities.chunked(into: batchSize) {
        let batchResult = batch.map { entity in
            generateStruct(from: entity).formatted().description
        }.joined(separator: "\n\n")
        
        results.append(batchResult)
        
        // Allow memory cleanup between batches
        autoreleasepool {
            // Batch processing completed
        }
    }
    
    return results.joined(separator: "\n\n")
}
```

#### Compilation Time Optimization

For projects generating large amounts of code:

1. **Split generated code into multiple files**
2. **Use incremental generation when possible**
3. **Consider parallel generation for independent modules**

```swift
import Foundation
import SyntaxKit

func generateCodeParallel(modules: [Module]) async -> [String: String] {
    await withTaskGroup(of: (String, String).self) { group in
        var results: [String: String] = [:]
        
        for module in modules {
            group.addTask {
                let code = generateModule(module).formatted().description
                return (module.name, code)
            }
        }
        
        for await (name, code) in group {
            results[name] = code
        }
        
        return results
    }
}
```

## Integration Testing

### Validating Generated Code

Create integration tests that verify generated code:

```swift
import Testing
import SyntaxKit

@Test func testGeneratedCodeCompiles() async throws {
    // Generate code from test configuration
    let config = TestConfiguration.sample
    let generatedCode = generateSwiftCode(from: config)
    
    // Write to temporary file
    let tempFile = URL.temporaryDirectory
        .appendingPathComponent("test-generated.swift")
    
    try generatedCode.write(to: tempFile, atomically: true, encoding: .utf8)
    
    // Verify it compiles
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["-typecheck", tempFile.path]
    
    try process.run()
    process.waitUntilExit()
    
    #expect(process.terminationStatus == 0, "Generated code should compile")
}
```

### End-to-End Workflow Testing

Test the complete integration pipeline:

```swift
@Test func testCompleteGenerationWorkflow() async throws {
    // 1. Start with input configuration
    let config = APIConfiguration.loadFromJSON()
    
    // 2. Generate Swift models
    let models = generateModels(from: config)
    
    // 3. Generate API client
    let client = generateAPIClient(from: config)
    
    // 4. Verify integration works
    let combinedCode = [models, client].joined(separator: "\n\n")
    
    // 5. Test compilation
    try await validateSwiftCodeCompiles(combinedCode)
    
    // 6. Test runtime behavior (if applicable)
    try await validateGeneratedCodeBehavior(combinedCode)
}
```

## Summary

Integrating SyntaxKit into existing projects requires careful consideration of build systems, team workflows, and deployment strategies. Key principles:

- **Separate generated from hand-written code**
- **Version control both configuration and output**
- **Automate generation in CI/CD pipelines**
- **Design for incremental updates**
- **Test generated code compilation and behavior**

Following these patterns ensures SyntaxKit enhances your development workflow without introducing complexity or maintenance burden.

## See Also

- <doc:Quick-Start-Guide>
- <doc:Creating-Macros-with-SyntaxKit>
- <doc:When-to-Use-SyntaxKit>
- <doc:Troubleshooting>
- ``Struct``
- ``Enum``
- ``Function``
- ``Class``