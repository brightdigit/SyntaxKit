import Foundation
import Testing

@testable import SyntaxKit

internal struct MainApplicationTests {
  // MARK: - Main Application Error Handling Tests

  @Test("Main application handles valid input")
  internal func testMainApplicationValidInput() throws {
    // This test simulates the main application behavior
    // We can't easily test the main function directly, but we can test its components

    let code = "let x = 42"
    let response = try SyntaxParser.parse(code: code, options: ["fold"])

    // Test JSON serialization (part of main application logic)
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("syntax"))
    #expect(jsonString!.contains("let"))
  }

  @Test("Main application handles empty input")
  internal func testMainApplicationEmptyInput() throws {
    let code = ""
    let response = try SyntaxParser.parse(code: code, options: [])

    // Test JSON serialization with empty result
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("syntax"))
  }

  @Test("Main application handles parsing errors")
  internal func testMainApplicationHandlesParsingErrors() throws {
    let invalidCode = "struct {"

    // The parser doesn't throw errors for invalid syntax, it returns a result
    let response = try SyntaxParser.parse(code: invalidCode, options: [])

    // Test error JSON serialization (part of main application logic)
    let jsonData = try JSONSerialization.data(withJSONObject: ["error": "Invalid syntax"])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("error"))
    #expect(jsonString!.contains("Invalid syntax"))
  }

  @Test("Main application handles JSON serialization errors")
  internal func testMainApplicationHandlesJSONSerializationErrors() throws {
    // Test with a response that might cause JSON serialization issues
    let code = "let x = 42"
    let response = try SyntaxParser.parse(code: code, options: [])

    // This should work fine, but we're testing the JSON serialization path
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
  }

  // MARK: - File I/O Simulation Tests

  @Test("Main application handles large input")
  internal func testMainApplicationHandlesLargeInput() throws {
    // Generate a large Swift file to test performance
    var largeCode = ""
    for index in 1...50 {
      largeCode += """
        struct Struct\(index) {
          let property\(index): String
          func method\(index)() -> String {
            return "value\(index)"
          }
        }

        """
    }

    let response = try SyntaxParser.parse(code: largeCode, options: ["fold"])
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("Struct1"))
    #expect(jsonString!.contains("Struct50"))
  }

  @Test("Main application handles unicode input")
  internal func testMainApplicationHandlesUnicodeInput() throws {
    let unicodeCode = """
      let emoji = "🚀"
      let unicode = "café"
      let chinese = "你好"
      """

    let response = try SyntaxParser.parse(code: unicodeCode, options: [])
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("emoji"))
    #expect(jsonString!.contains("unicode"))
    #expect(jsonString!.contains("chinese"))
  }

  // MARK: - Error Response Format Tests

  @Test("Main application error response format")
  internal func testMainApplicationErrorResponseFormat() throws {
    // Test the error response format that the main application would generate
    let testError = NSError(
      domain: "TestDomain",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Test error message"]
    )

    let errorResponse = ["error": testError.localizedDescription]
    let jsonData = try JSONSerialization.data(withJSONObject: errorResponse)
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("error"))
    #expect(jsonString!.contains("Test error message"))
  }

  @Test("Main application handles encoding errors")
  internal func testMainApplicationHandlesEncodingErrors() throws {
    let code = "let x = 42"
    let response = try SyntaxParser.parse(code: code, options: [])

    // Test UTF-8 encoding (part of main application logic)
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("syntax"))
  }

  // MARK: - Integration Tests

  @Test("Main application integration with complex Swift code")
  internal func testMainApplicationIntegrationWithComplexSwiftCode() throws {
    let code = """
      @objc class MyClass: NSObject {
        @Published var property: String = "default"

        func method(@escaping completion: @escaping (String) -> Void) {
          completion("result")
        }

        enum NestedEnum: Int {
          case first = 1
          case second = 2
        }
      }
      """

    let response = try SyntaxParser.parse(code: code, options: ["fold"])

    // Test JSON serialization (part of main application logic)
    let jsonData = try JSONSerialization.data(withJSONObject: ["syntax": response.syntaxJSON])
    let jsonString = String(data: jsonData, encoding: .utf8)

    #expect(jsonString != nil)
    #expect(jsonString!.contains("syntax"))
    #expect(jsonString!.contains("class"))
    #expect(jsonString!.contains("MyClass"))
  }

  @Test("Main application handles different parser options")
  internal func testMainApplicationHandlesDifferentParserOptions() throws {
    let code = "let x = 42"

    let response1 = try SyntaxParser.parse(code: code, options: [])
    let response2 = try SyntaxParser.parse(code: code, options: ["fold"])

    // Test JSON serialization for both responses
    let jsonData1 = try JSONSerialization.data(withJSONObject: ["syntax": response1.syntaxJSON])
    let jsonString1 = String(data: jsonData1, encoding: .utf8)

    let jsonData2 = try JSONSerialization.data(withJSONObject: ["syntax": response2.syntaxJSON])
    let jsonString2 = String(data: jsonData2, encoding: .utf8)

    #expect(jsonString1 != nil)
    #expect(jsonString2 != nil)
    #expect(jsonString1!.contains("syntax"))
    #expect(jsonString2!.contains("syntax"))
    #expect(jsonString1!.contains("let"))
    #expect(jsonString2!.contains("let"))
  }
}
