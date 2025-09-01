#!/usr/bin/env swift

import Foundation

// This is a complete working demonstration of SyntaxKit's enum generation
// Run this file with: swift QuickStartDemo.swift

// For this demo, we'll simulate SyntaxKit functionality
// In a real project, you would: import SyntaxKit

// MARK: - Configuration Structures

struct EnumConfig: Codable {
    let name: String
    let cases: [EnumCase]
}

struct EnumCase: Codable {
    let name: String
    let value: String
}

// MARK: - JSON Configuration Data

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

// MARK: - SyntaxKit-Style Code Generator

func generateEnum(from json: String) -> String {
    print("🔄 Parsing JSON configuration...")
    
    // Parse JSON configuration
    guard let data = json.data(using: .utf8),
          let config = try? JSONDecoder().decode(EnumConfig.self, from: data) else {
        print("❌ Invalid JSON configuration")
        return "// Invalid JSON configuration"
    }
    
    print("✅ Successfully parsed: \(config.cases.count) enum cases")
    print("🔨 Generating Swift enum: \(config.name)")
    
    // In real SyntaxKit, this would use the declarative DSL:
    // let enumDecl = Enum(config.name, conformsTo: ["Int", "CaseIterable"]) {
    //     for enumCase in config.cases {
    //         Case(enumCase.name, rawValue: enumCase.value)
    //     }
    // }
    // return enumDecl.formatted().description
    
    // For this demo, we'll generate the Swift code manually
    var swiftCode = "enum \(config.name): Int, CaseIterable {\n"
    
    for enumCase in config.cases {
        swiftCode += "    case \(enumCase.name) = \(enumCase.value)\n"
    }
    
    swiftCode += "}"
    
    print("✨ Code generation complete!")
    return swiftCode
}

// MARK: - Demo Execution

func runDemo() {
    print("🚀 SyntaxKit Quick Start Demo")
    print("═══════════════════════════════════════")
    print()
    
    print("📋 Input JSON Configuration:")
    print(jsonConfig)
    print()
    
    // Generate the Swift code
    let swiftCode = generateEnum(from: jsonConfig)
    
    print()
    print("🎯 Generated Swift Code:")
    print("═══════════════════════════════════════")
    print(swiftCode)
    print("═══════════════════════════════════════")
    print()
    
    print("🎉 Success! You've just generated Swift code from JSON!")
    print()
    print("💡 Key Insight:")
    print("   Instead of manually writing enums, you can now generate them")
    print("   dynamically from any data source: APIs, databases, config files!")
    print()
    print("📚 Next Steps:")
    print("   • Try modifying the JSON configuration above")
    print("   • Add more enum cases or change the enum name")
    print("   • Check out the macro tutorial for advanced usage")
    print("   • Download the complete Swift Playground")
}

// MARK: - Run the Demo

runDemo()