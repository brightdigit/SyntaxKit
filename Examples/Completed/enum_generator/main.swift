import SyntaxKit

// This example demonstrates dynamic enum generation using SyntaxKit
// Run: swift run enum-generator-example

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
}

// MARK: - Generator

func generateEnum(from config: EnumConfiguration) -> Enum {
    var enumDecl = Enum(config.name) {
        for caseConfig in config.cases {
            if let rawValue = caseConfig.rawValue {
                EnumCase(caseConfig.name).equals(rawValue)
            } else {
                EnumCase(caseConfig.name)
            }
        }
    }
    
    if let rawType = config.rawType {
        enumDecl = enumDecl.inherits(rawType)
    }
    
    for conformance in config.conformances {
        enumDecl = enumDecl.inherits(conformance)
    }
    
    if let accessLevel = config.accessLevel {
        enumDecl = enumDecl.accessLevel(accessLevel)
    }
    
    return enumDecl
}

// MARK: - Example Configurations

let apiEndpoints = EnumConfiguration(
    name: "APIEndpoint",
    rawType: "String",
    cases: [
        EnumCaseConfiguration(name: "users", rawValue: "\"/api/users\""),
        EnumCaseConfiguration(name: "posts", rawValue: "\"/api/posts\""),
        EnumCaseConfiguration(name: "comments", rawValue: "\"/api/comments\"")
    ],
    conformances: ["CaseIterable"],
    accessLevel: .public
)

let httpStatus = EnumConfiguration(
    name: "HTTPStatus", 
    rawType: "Int",
    cases: [
        EnumCaseConfiguration(name: "ok", rawValue: "200"),
        EnumCaseConfiguration(name: "notFound", rawValue: "404"),
        EnumCaseConfiguration(name: "serverError", rawValue: "500")
    ],
    conformances: ["CaseIterable"],
    accessLevel: .public
)

// MARK: - Generate Code

let example = Group {
    Line("// MARK: - Generated Enums")
    Line()
    
    generateEnum(from: apiEndpoints)
        .comment {
            Line(.doc, "API endpoints for the application")
        }
    
    Line()
    
    generateEnum(from: httpStatus)
        .comment {
            Line(.doc, "HTTP status codes")
        }
}

print(example.generateCode())