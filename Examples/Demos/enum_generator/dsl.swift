import SyntaxKit
import Foundation

// MARK: - Before vs After Integration Demo
// This example demonstrates the value proposition of SyntaxKit for dynamic enum generation
// by comparing manual maintenance (before) vs automated generation (after)

// MARK: - JSON Configuration Support
struct APIConfiguration: Codable {
    let endpoints: [String: String]
    let statusCodes: [String: Int]
    let errorTypes: [ErrorTypeConfig]
}

struct ErrorTypeConfig: Codable {
    let name: String
    let associatedData: [String]?
}

// MARK: - Configuration Models

struct EnumConfiguration {
    let name: String
    let rawType: String?
    let cases: [EnumCaseConfiguration]
    let conformances: [String]
    let accessLevel: AccessModifier?
}

struct EnumCaseConfiguration {
    let name: String
    let rawValue: String?
    let associatedValues: [AssociatedValue]?
}

struct AssociatedValue {
    let label: String?
    let type: String
}

// MARK: - Enum Generator

struct EnumGenerator {
    let configuration: EnumConfiguration
    
    func generate() -> Enum {
        var enumDeclaration = Enum(configuration.name) {
            for caseConfig in configuration.cases {
                if let associatedValues = caseConfig.associatedValues, !associatedValues.isEmpty {
                    // Enum case with associated values
                    let parameters = associatedValues.map { assocValue in
                        if let label = assocValue.label {
                            return "\(label): \(assocValue.type)"
                        } else {
                            return assocValue.type
                        }
                    }.joined(separator: ", ")
                    EnumCase(caseConfig.name).call(parameters)
                } else if let rawValue = caseConfig.rawValue {
                    // Enum case with raw value
                    EnumCase(caseConfig.name).equals(rawValue)
                } else {
                    // Simple enum case
                    EnumCase(caseConfig.name)
                }
            }
        }
        
        // Add raw type inheritance if specified
        if let rawType = configuration.rawType {
            enumDeclaration = enumDeclaration.inherits(rawType)
        }
        
        // Add conformances
        for conformance in configuration.conformances {
            enumDeclaration = enumDeclaration.inherits(conformance)
        }
        
        // Set access level
        if let accessLevel = configuration.accessLevel {
            enumDeclaration = enumDeclaration.accessLevel(accessLevel)
        }
        
        return enumDeclaration
    }
}

// MARK: - Example: API Endpoints (String Raw Values)

let apiEndpointsConfig = EnumConfiguration(
    name: "APIEndpoint",
    rawType: "String",
    cases: [
        EnumCaseConfiguration(name: "users", rawValue: "\"/api/users\"", associatedValues: nil),
        EnumCaseConfiguration(name: "posts", rawValue: "\"/api/posts\"", associatedValues: nil),
        EnumCaseConfiguration(name: "comments", rawValue: "\"/api/comments\"", associatedValues: nil),
        EnumCaseConfiguration(name: "userProfile", rawValue: "\"/api/users/{id}\"", associatedValues: nil)
    ],
    conformances: ["CaseIterable"],
    accessLevel: .public
)

// MARK: - Example: Network Errors (Associated Values)

let networkErrorConfig = EnumConfiguration(
    name: "NetworkError",
    rawType: nil,
    cases: [
        EnumCaseConfiguration(
            name: "invalidURL",
            rawValue: nil,
            associatedValues: [AssociatedValue(label: "url", type: "String")]
        ),
        EnumCaseConfiguration(
            name: "httpError",
            rawValue: nil,
            associatedValues: [
                AssociatedValue(label: "statusCode", type: "Int"),
                AssociatedValue(label: "message", type: "String")
            ]
        ),
        EnumCaseConfiguration(name: "networkUnavailable", rawValue: nil, associatedValues: nil),
        EnumCaseConfiguration(
            name: "decodingError",
            rawValue: nil,
            associatedValues: [AssociatedValue(label: nil, type: "DecodingError")]
        )
    ],
    conformances: ["Error", "Equatable"],
    accessLevel: .public
)

// MARK: - Example: HTTP Status Codes (Integer Raw Values)

let httpStatusConfig = EnumConfiguration(
    name: "HTTPStatus",
    rawType: "Int",
    cases: [
        EnumCaseConfiguration(name: "ok", rawValue: "200", associatedValues: nil),
        EnumCaseConfiguration(name: "created", rawValue: "201", associatedValues: nil),
        EnumCaseConfiguration(name: "badRequest", rawValue: "400", associatedValues: nil),
        EnumCaseConfiguration(name: "unauthorized", rawValue: "401", associatedValues: nil),
        EnumCaseConfiguration(name: "forbidden", rawValue: "403", associatedValues: nil),
        EnumCaseConfiguration(name: "notFound", rawValue: "404", associatedValues: nil),
        EnumCaseConfiguration(name: "internalServerError", rawValue: "500", associatedValues: nil)
    ],
    conformances: ["CaseIterable"],
    accessLevel: .public
)

// MARK: - Generate All Examples

let enumExample = Group {
    Line("// Generated Enums - Demonstrating dynamic enum creation with SyntaxKit")
    Line()
    
    EnumGenerator(configuration: apiEndpointsConfig).generate()
        .comment {
            Line(.doc, "API endpoints for the application")
            Line(.doc, "")
            Line(.doc, "Use this enum to ensure type-safe API endpoint references")
        }
    
    Line()
    
    EnumGenerator(configuration: networkErrorConfig).generate()
        .comment {
            Line(.doc, "Network-related errors that can occur during API calls")
        }
    
    Line()
    
    EnumGenerator(configuration: httpStatusConfig).generate()
        .comment {
            Line(.doc, "Standard HTTP status codes")
        }
}

// MARK: - Load Configuration and Generate

func loadConfigAndGenerate() {
    // Load configuration from JSON file
    guard let configData = try? Data(contentsOf: URL(fileURLWithPath: "api-config.json")),
          let apiConfig = try? JSONDecoder().decode(APIConfiguration.self, from: configData) else {
        print("Could not load api-config.json")
        return
    }
    
    // Convert to our enum configurations
    let endpointConfig = EnumConfiguration(
        name: "APIEndpoint",
        rawType: "String", 
        cases: apiConfig.endpoints.map { key, value in
            EnumCaseConfiguration(name: key, rawValue: "\"\(value)\"", associatedValues: nil)
        },
        conformances: ["CaseIterable"],
        accessLevel: .public
    )
    
    let statusConfig = EnumConfiguration(
        name: "HTTPStatus",
        rawType: "Int",
        cases: apiConfig.statusCodes.map { key, value in 
            EnumCaseConfiguration(name: key, rawValue: "\(value)", associatedValues: nil)
        },
        conformances: ["CaseIterable"], 
        accessLevel: .public
    )
    
    let errorConfig = EnumConfiguration(
        name: "NetworkError",
        rawType: nil,
        cases: apiConfig.errorTypes.map { errorType in
            let associatedValues = errorType.associatedData?.map { data in
                AssociatedValue(label: nil, type: data)
            }
            return EnumCaseConfiguration(
                name: errorType.name,
                rawValue: nil, 
                associatedValues: associatedValues
            )
        },
        conformances: ["Error", "Equatable"],
        accessLevel: .public
    )
    
    // Generate the complete example
    let generatedCode = Group {
        Line("// MARK: - Generated API Enums")
        Line("// ⚡ Auto-generated from api-config.json using SyntaxKit")
        Line("// ✅ Always synchronized with backend configuration")
        Line("// 🚀 Generated on: \(ISO8601DateFormatter().string(from: Date()))")
        Line()
        
        EnumGenerator(configuration: endpointConfig).generate()
            .comment {
                Line(.doc, "API endpoints for the application")
                Line(.doc, "")
                Line(.doc, "⚡ Generated automatically from api-config.json")
                Line(.doc, "✅ Always synchronized with backend configuration")
            }
        
        Line()
        
        EnumGenerator(configuration: statusConfig).generate()
            .comment {
                Line(.doc, "HTTP status codes for API responses") 
                Line(.doc, "")
                Line(.doc, "⚡ Generated automatically from api-config.json")
                Line(.doc, "✅ Complete coverage of all backend status codes")
            }
        
        Line()
        
        EnumGenerator(configuration: errorConfig).generate()
            .comment {
                Line(.doc, "Network errors that can occur during API calls")
                Line(.doc, "")
                Line(.doc, "⚡ Generated automatically from api-config.json")
                Line(.doc, "✅ Perfect structural match with backend error format")
            }
    }
    
    print(generatedCode.generateCode())
}

// Run the demo
loadConfigAndGenerate()