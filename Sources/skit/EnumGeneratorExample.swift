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
        for enumCase in config.cases {
            EnumCase(enumCase.name).equals(Int(enumCase.value) ?? 0)
        }
    }.inherits("Int", "CaseIterable")
    
    // Generate Swift source code
    return enumDecl.generateCode()
}

// Test the example from the Quick Start guide
func runQuickStartExample() {
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
    
    // Generate the Swift code
    let swiftCode = generateEnum(from: jsonConfig)
    
    // Print the generated Swift enum
    print("Generated Swift Code:")
    print(String(repeating: "=", count: 40))
    print(swiftCode)
    print(String(repeating: "=", count: 40))
}

// Additional examples for the playground
func runAdditionalExamples() {
    print("\nAdditional Examples:\n")
    
    // Extended HTTP Status example
    let extendedHTTPConfig = """
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
    
    print("Extended HTTP Status:")
    print(generateEnum(from: extendedHTTPConfig))
    print()
    
    // Priority example
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
    
    print("Priority Enum:")
    print(generateEnum(from: priorityConfig))
}
