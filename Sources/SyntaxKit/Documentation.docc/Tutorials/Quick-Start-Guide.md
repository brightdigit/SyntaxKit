# Quick Start Guide

Get up and running with SyntaxKit in under 5 minutes. This tutorial will take you from zero to generating Swift code, showing you the power of dynamic code generation.

## What You'll Build

In this quick start, you'll create a simple enum generator that reads configuration from JSON and produces Swift enum code. You'll see firsthand how SyntaxKit transforms external data into clean, compilable Swift code.

**Time to complete**: 5 minutes  
**Prerequisites**: Basic Swift knowledge, Xcode 16.4+

## Step 1: Add SyntaxKit to Your Project (2 minutes)

### Using Swift Package Manager

1. **In Xcode**: Go to File → Add Package Dependencies
2. **Enter URL**: `https://github.com/brightdigit/SyntaxKit.git`
3. **Choose Version**: Use "Up to Next Major Version" starting from 1.0.0
4. **Add to Target**: Select your target and click "Add Package"

### Using Package.swift

Add SyntaxKit to your `Package.swift` file:

<!-- skip-test -->
```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .macOS(.v13), .iOS(.v13), .watchOS(.v6), .tvOS(.v13), .visionOS(.v1)
    ],
    dependencies: [
        .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["SyntaxKit"]
        )
    ]
)
```

### Import SyntaxKit

In your Swift file, add the import:

```swift
import SyntaxKit
```

That's it! SyntaxKit is now available in your project.

## Step 2: Create Your First Dynamic Enum (2 minutes)

Let's create an enum generator that reads from JSON configuration. This demonstrates the core power of SyntaxKit: transforming external data into Swift code.

### The JSON Configuration

First, create this JSON configuration:

```json
{
  "name": "HTTPStatus",
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "notFound", "value": "404"},
    {"name": "serverError", "value": "500"}
  ]
}
```

### The Enum Generator

Now create the generator code:

```swift
import SyntaxKit
import Foundation

// Define our configuration structure
struct EnumConfig: Codable {
    let name: String
    let cases: [EnumCaseConfig]
}

struct EnumCaseConfig: Codable {
    let name: String
    let value: String
}

// The magic happens here - generate Swift enum from JSON
func generateEnum(from json: String) -> String {
    // Parse JSON configuration
    guard let data = json.data(using: .utf8),
          let config = try? JSONDecoder().decode(EnumConfig.self, from: data) else {
        return "// Invalid JSON configuration"
    }
    
    // Create enum using SyntaxKit's declarative DSL
    let enumDecl = Enum(config.name) {
        for caseConfig in config.cases {
            EnumCase(caseConfig.name).equals(caseConfig.value)
        }
    }
    .inherits("Int", "CaseIterable")
    
    // Generate Swift source code
    return enumDecl.syntax.description
}
```

### The JSON Input

```swift
let jsonConfig = """
{
  "name": "HTTPStatus",
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "notFound", "value": "404"},
    {"name": "serverError", "value": "500"}
  ]
}
"""
```

## Step 3: See It in Action (1 minute)

Run the generator and see the magic happen:

```swift
import Foundation
import SyntaxKit

// Configuration model
struct EnumConfig: Codable {
    let name: String
    let cases: [EnumCaseConfig]
}

struct EnumCaseConfig: Codable {
    let name: String
    let value: String
}

// Sample JSON configuration
let jsonConfig = """
{
  "name": "HTTPStatus",
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "notFound", "value": "404"},
    {"name": "serverError", "value": "500"}
  ]
}
"""

// Generator function
func generateEnum(from json: String) -> String {
    guard let data = json.data(using: .utf8),
          let config = try? JSONDecoder().decode(EnumConfig.self, from: data) else {
        return "// Invalid JSON configuration"
    }
    
    let enumDecl = Enum(config.name) {
        for caseConfig in config.cases {
            EnumCase(caseConfig.name).equals(caseConfig.value)
        }
    }
    .inherits("Int", "CaseIterable")
    
    return enumDecl.syntax.description
}

// Generate the Swift code with visible progress
let swiftCode = generateEnum(from: jsonConfig)

// Print the results with formatting
print("🎯 Generated Swift Code:")
print("═══════════════════════════════════════")
print(swiftCode)
print("═══════════════════════════════════════")
```

**Complete runnable example**:

Save this as `QuickStartDemo.swift` and run with `swift QuickStartDemo.swift`:

```swift
import Foundation

// Configuration structures
struct EnumConfig: Codable {
    let name: String
    let cases: [EnumCaseConfig]
}

struct EnumCaseConfig: Codable {
    let name: String
    let value: String
}

// Enhanced generator with visible progress
func generateEnum(from json: String) -> String {
    print("🔄 Parsing JSON configuration...")
    
    guard let data = json.data(using: .utf8),
          let config = try? JSONDecoder().decode(EnumConfig.self, from: data) else {
        print("❌ Invalid JSON configuration")
        return "// Invalid JSON configuration"
    }
    
    print("✅ Successfully parsed: \(config.cases.count) enum cases")
    print("🔨 Generating Swift enum: \(config.name)")
    
    var swiftCode = "enum \(config.name): Int, CaseIterable {\n"
    for enumCase in config.cases {
        swiftCode += "    case \(enumCase.name) = \(enumCase.value)\n"
    }
    swiftCode += "}"
    
    print("✨ Code generation complete!")
    return swiftCode
}

// JSON configuration
let jsonConfig = """
{
  "name": "HTTPStatus", 
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "created", "value": "201"}, 
    {"name": "notFound", "value": "404"},
    {"name": "serverError", "value": "500"}
  ]
}
"""

// Run the demo
print("🚀 SyntaxKit Quick Start Demo")
print("═══════════════════════════════════════")
let swiftCode = generateEnum(from: jsonConfig)
print("🎯 Generated Swift Code:")
print("═══════════════════════════════════════")
print(swiftCode)
print("═══════════════════════════════════════")
print("🎉 Success! You've generated Swift code from JSON!")
```

**Output**:
```
🚀 SyntaxKit Quick Start Demo
═══════════════════════════════════════
🔄 Parsing JSON configuration...
✅ Successfully parsed: 4 enum cases
🔨 Generating Swift enum: HTTPStatus
✨ Code generation complete!
🎯 Generated Swift Code:
═══════════════════════════════════════
enum HTTPStatus: Int, CaseIterable {
    case ok = 200
    case created = 201
    case notFound = 404
    case serverError = 500
}
═══════════════════════════════════════
🎉 Success! You've generated Swift code from JSON!
```

### The "Aha!" Moment

**This is the power of SyntaxKit**: You just transformed JSON configuration into clean, compilable Swift code! 

Compare this to manually maintaining enums:
- ❌ **Manual approach**: Edit Swift files every time your API changes
- ✅ **SyntaxKit approach**: Update JSON config, regenerate automatically

The generated code is identical to hand-written Swift, but now it can be created dynamically from any data source.

## Try It Yourself

### Experiment 1: Add More Cases
Try adding more HTTP status codes to the JSON:

```json
{
  "name": "HTTPStatus",
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "created", "value": "201"},
    {"name": "notFound", "value": "404"},
    {"name": "serverError", "value": "500"},
    {"name": "badGateway", "value": "502"}
  ]
}
```

### Experiment 2: Create Different Enums
Try generating a different enum entirely:

```json
{
  "name": "Priority",
  "cases": [
    {"name": "low", "value": "1"},
    {"name": "medium", "value": "2"},
    {"name": "high", "value": "3"},
    {"name": "critical", "value": "4"}
  ]
}
```

### Experiment 3: Playground Fun
Copy all the code above into a Swift Playground and experiment with different configurations. See how quickly you can generate completely different enums!

## What You've Accomplished

In just 5 minutes, you've:
- ✅ Added SyntaxKit to your project
- ✅ Created a dynamic enum generator
- ✅ Transformed JSON into Swift code
- ✅ Seen the power of declarative code generation

**The key insight**: Instead of writing static Swift code, you're now generating it dynamically from external data. This opens up powerful possibilities for API clients, database models, and code generation tools.

## Next Steps

Congratulations! You've just generated Swift code from external data. Ready to explore what else SyntaxKit can do?

### 🎮 **Start Here: Download the Playground**
**[📥 Download Quick Start Playground](https://github.com/brightdigit/SyntaxKit/releases/latest/download/SyntaxKit-QuickStart.playground.zip)** - All examples above, ready to run in Xcode

### 🎯 **Quick Wins to Try Right Now**

1. **Modify the playground**: Change the JSON configs and see instant results
2. **Add SyntaxKit to your project**: Use the installation steps above
3. **Generate your own enums**: Replace the JSON with your app's actual data

### 💡 **Advanced Applications to Explore**

- **API Clients**: Generate model enums from OpenAPI specifications
- **Database Models**: Create Swift enums from database schema
- **Configuration Management**: Transform environment configs into type-safe Swift
- **Build Tools**: Create CLI tools that generate Swift code from templates

## Summary

SyntaxKit transforms how you approach code generation in Swift. Instead of manually maintaining repetitive code structures, you can generate them dynamically from external data sources.

**Key takeaways**:
- SyntaxKit uses a declarative DSL for clean, readable code generation
- Generated code is identical to hand-written Swift code  
- Perfect for macros, API clients, and developer tools
- Built on Apple's SwiftSyntax for reliability and performance

You're now ready to explore the full power of dynamic Swift code generation with SyntaxKit!

## See Also

- ``Enum``
- ``Case``  
- ``Struct``
- ``Function``
- ``Class``
