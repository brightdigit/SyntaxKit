#!/usr/bin/env swift

// enum_generator.swift - Automated enum generation using SyntaxKit
// ✅ Always generates perfect, synchronized Swift enums from backend configuration

import Foundation
import SyntaxKit

// MARK: - Configuration Models

struct APIConfiguration: Codable {
    let endpoints: [String: String]
    let statusCodes: [String: Int] 
    let errorTypes: [ErrorTypeConfiguration]
}

struct ErrorTypeConfiguration: Codable {
    let name: String
    let associatedData: [String]?
}

// MARK: - SyntaxKit-Powered Enum Generator

class EnumGenerator {
    let config: APIConfiguration
    
    init(configPath: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        self.config = try JSONDecoder().decode(APIConfiguration.self, from: data)
    }
    
    func generateAPIEndpoints() -> Enum {
        Enum("APIEndpoint") {
            for (caseName, endpoint) in config.endpoints.sorted(by: { $0.key < $1.key }) {
                EnumCase(caseName).equals("\"\(endpoint)\"")
            }
        }
        .inherits("String")
        .inherits("CaseIterable") 
        .accessLevel(.public)
        .comment {
            Line(.doc, "API endpoints for the application")
            Line(.doc, "")
            Line(.doc, "⚡ Generated automatically from api-config.json")
            Line(.doc, "✅ Always synchronized with backend configuration")
        }
    }
    
    func generateHTTPStatus() -> Enum {
        Enum("HTTPStatus") {
            for (caseName, statusCode) in config.statusCodes.sorted(by: { $0.value < $1.value }) {
                EnumCase(caseName).equals("\(statusCode)")
            }
        }
        .inherits("Int")
        .inherits("CaseIterable")
        .accessLevel(.public)
        .comment {
            Line(.doc, "HTTP status codes for API responses")
            Line(.doc, "")
            Line(.doc, "⚡ Generated automatically from api-config.json")
            Line(.doc, "✅ Complete coverage of all backend status codes")
        }
    }
    
    func generateNetworkError() -> Enum {
        Enum("NetworkError") {
            for errorType in config.errorTypes {
                if let associatedData = errorType.associatedData, !associatedData.isEmpty {
                    let params = associatedData.joined(separator: ", ")
                    EnumCase(errorType.name).call(params)
                } else {
                    EnumCase(errorType.name)
                }
            }
        }
        .inherits("Error")
        .inherits("Equatable")
        .accessLevel(.public)
        .comment {
            Line(.doc, "Network errors that can occur during API calls")
            Line(.doc, "")
            Line(.doc, "⚡ Generated automatically from api-config.json")  
            Line(.doc, "✅ Perfect structural match with backend error format")
        }
    }
    
    func generateAll() -> Group {
        Group {
            Line("// MARK: - Generated API Enums")
            Line("// ⚡ Auto-generated from api-config.json using SyntaxKit")
            Line("// ✅ Always synchronized with backend configuration")
            Line("// 🚀 Generated on: \(ISO8601DateFormatter().string(from: Date()))")
            Line()
            
            generateAPIEndpoints()
            Line()
            generateHTTPStatus()
            Line() 
            generateNetworkError()
        }
    }
}

// MARK: - CLI Interface

if CommandLine.arguments.count < 2 {
    print("Usage: swift enum_generator.swift <config.json>")
    exit(1)
}

let configPath = CommandLine.arguments[1]

do {
    let generator = try EnumGenerator(configPath: configPath)
    let generatedCode = generator.generateAll().generateCode()
    print(generatedCode)
} catch {
    print("Error: \(error)")
    exit(1)
}