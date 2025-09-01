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
    let cases: [EnumCase]
}

struct EnumCase: Codable {
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
    let enumDecl = Enum(config.name, conformsTo: ["Int", "CaseIterable"]) {
        for enumCase in config.cases {
            Case(enumCase.name, rawValue: enumCase.value)
        }
    }
    
    // Generate Swift source code
    return enumDecl.formatted().description
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
// Generate the Swift code
let swiftCode = generateEnum(from: jsonConfig)

// Print the generated Swift enum
print("Generated Swift Code:")
print("=" * 40)
print(swiftCode)
print("=" * 40)
```

**Output**:
```swift
enum HTTPStatus: Int, CaseIterable {
    case ok = 200
    case notFound = 404
    case serverError = 500
}
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

Ready to dive deeper? Here are your options:

### 🎯 **For Macro Development**
<doc:Creating-Macros-with-SyntaxKit> - Build powerful Swift macros with SyntaxKit's clean DSL

### 🏗️ **For Advanced Examples**
- [Enum Generator CLI Tool](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation) - Complete command-line enum generator
- [Best Practices Guide](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation) - Patterns for maintainable code generation

### 📚 **For Understanding When to Use SyntaxKit**
<doc:When-to-Use-SyntaxKit> - Decision framework for choosing SyntaxKit vs regular Swift

### 🎮 **For Hands-On Learning**
Download our [Quick Start Playground](https://github.com/brightdigit/SyntaxKit/releases/latest/download/SyntaxKit-QuickStart.playground.zip) - Complete working examples you can run immediately

## Download Playground

Want to experiment right away? Download our Swift Playground with all examples ready to run:

**[📥 Download SyntaxKit Quick Start Playground](https://github.com/brightdigit/SyntaxKit/releases/latest/download/SyntaxKit-QuickStart.playground.zip)**

The playground includes:
- Complete enum generator example
- Multiple JSON configurations to try
- Interactive experiments
- Links to advanced topics

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