import Foundation

// 🚀 SyntaxKit Quick Start Playground
// ═══════════════════════════════════════════════════════════════════
//
// Welcome to SyntaxKit! This playground demonstrates the power of 
// dynamic Swift code generation. You'll see how to transform JSON 
// configuration into clean, compilable Swift enums.
//
// What makes this special? Instead of manually writing and maintaining
// enums, you can generate them from any data source: APIs, databases,
// config files, or user input!
//
// ═══════════════════════════════════════════════════════════════════

// MARK: - Configuration Structures

/// Configuration structure for enum generation
struct EnumConfig: Codable {
    let name: String
    let cases: [EnumCase]
}

/// Individual enum case configuration
struct EnumCase: Codable {
    let name: String
    let value: String
}

// MARK: - Sample JSON Configurations

/// HTTP Status codes - perfect for API clients
let httpStatusConfig = """
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
"""

/// Priority levels - great for task management
let priorityConfig = """
{
  "name": "Priority",
  "cases": [
    {"name": "low", "value": "1"},
    {"name": "medium", "value": "2"},
    {"name": "high", "value": "3"},
    {"name": "critical", "value": "4"}
  ]
}
"""

/// Log levels - useful for debugging systems
let logLevelConfig = """
{
  "name": "LogLevel",
  "cases": [
    {"name": "debug", "value": "0"},
    {"name": "info", "value": "1"},
    {"name": "warning", "value": "2"},
    {"name": "error", "value": "3"}
  ]
}
"""

// MARK: - The Magic: SyntaxKit-Style Code Generator

/// Generates Swift enum code from JSON configuration
/// In a real project with SyntaxKit, this would use the declarative DSL:
/// ```swift
/// let enumDecl = Enum(config.name, conformsTo: ["Int", "CaseIterable"]) {
///     for enumCase in config.cases {
///         Case(enumCase.name, rawValue: enumCase.value)
///     }
/// }
/// return enumDecl.formatted().description
/// ```
func generateEnum(from json: String, showProgress: Bool = true) -> String {
    if showProgress {
        print("🔄 Parsing JSON configuration...")
    }

    // Parse JSON configuration
    guard let data = json.data(using: .utf8),
          let config = try? JSONDecoder().decode(EnumConfig.self, from: data) else {
        if showProgress {
            print("❌ Invalid JSON configuration")
        }
        return "// Invalid JSON configuration"
    }

    if showProgress {
        print("✅ Successfully parsed: \(config.cases.count) enum cases")
        print("🔨 Generating Swift enum: \(config.name)")
    }

    // Generate Swift enum code
    var swiftCode = "enum \(config.name): Int, CaseIterable {\n"

    for enumCase in config.cases {
        swiftCode += "    case \(enumCase.name) = \(enumCase.value)\n"
    }

    swiftCode += "}"

    if showProgress {
        print("✨ Code generation complete!")
    }

    return swiftCode
}

/// Helper function to demonstrate enum generation with nice formatting
func demonstrateGeneration(title: String, config: String) {
    print("\n🎯 \(title)")
    print("═══════════════════════════════════════")
    print()

    print("📋 Input JSON Configuration:")
    print(config)
    print()

    let swiftCode = generateEnum(from: config)

    print()
    print("🎯 Generated Swift Code:")
    print("═══════════════════════════════════════")
    print(swiftCode)
    print("═══════════════════════════════════════")
    print()
}

// MARK: - Interactive Demonstrations

print("🚀 Welcome to SyntaxKit Quick Start Playground!")
print("═══════════════════════════════════════════════════════════════════")
print()
print("This playground demonstrates dynamic Swift code generation.")
print("You'll see how external data transforms into clean Swift enums!")
print()

// Demo 1: HTTP Status Codes
demonstrateGeneration(title: "HTTP Status Enum Generation", config: httpStatusConfig)

// Demo 2: Priority Levels  
demonstrateGeneration(title: "Priority Level Enum Generation", config: priorityConfig)

// Demo 3: Log Levels
demonstrateGeneration(title: "Log Level Enum Generation", config: logLevelConfig)

// MARK: - Try It Yourself!

print("🎮 Try It Yourself!")
print("═══════════════════════════════════════")
print()
print("1. Modify any of the JSON configurations above")
print("2. Create your own configuration")
print("3. Run the playground again to see the results")
print()

// Example: Create your own enum configuration
let yourCustomConfig = """
{
  "name": "YourEnum",
  "cases": [
    {"name": "firstCase", "value": "1"},
    {"name": "secondCase", "value": "2"}
  ]
}
"""

print("💡 Your Custom Configuration Example:")
print("═══════════════════════════════════════")
let customResult = generateEnum(from: yourCustomConfig)
print(customResult)
print()

// MARK: - Key Insights

print("🔑 Key Insights from This Demo:")
print("═══════════════════════════════════════")
print("• External data → Swift code automatically")
print("• No manual enum maintenance required")
print("• Perfect for API responses, database schemas")
print("• Generated code is identical to hand-written code")
print("• SyntaxKit makes complex code generation simple")
print()

// MARK: - Real-World Applications

print("🌍 Real-World Applications:")
print("═══════════════════════════════════════")
print("• API client enums from OpenAPI specs")
print("• Database model enums from schema definitions")
print("• Configuration enums from environment variables")
print("• Localization enums from translation files")
print("• Error code enums from documentation")
print()

// MARK: - Next Steps

print("📚 Next Steps - Explore Advanced SyntaxKit:")
print("═══════════════════════════════════════")
print("• Macro Development: Build Swift macros with SyntaxKit")
print("• Advanced Examples: Complex code generation patterns")
print("• Best Practices: Maintainable code generation strategies")
print("• Integration Guide: Add SyntaxKit to existing projects")
print()
print("🎉 Congratulations! You've mastered SyntaxKit basics!")
print("Visit: https://github.com/brightdigit/SyntaxKit for more examples")
