//
//  QuickStartDemo.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

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
    let config = try? JSONDecoder().decode(EnumConfig.self, from: data)
  else {
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
  print("   • Integrate SyntaxKit into your own projects")
}

// MARK: - Run the Demo

runDemo()
