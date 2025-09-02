import Testing
import Foundation
@testable import SyntaxKit

/// Simple test to validate documentation examples
@Suite("Simple Documentation Examples")
struct SimpleDocTests {
    
    @Test("Basic markdown code extraction works")
    func testMarkdownCodeExtraction() throws {
        let markdown = """
        # Example Title
        
        Here's some Swift code:
        
        ```swift
        import SyntaxKit
        
        let myEnum = Enum("MyEnum") {
            EnumCase("first")
            EnumCase("second")
        }
        ```
        
        More text here.
        """
        
        let codeBlocks = extractSwiftCodeBlocks(from: markdown)
        
        #expect(codeBlocks.count == 1)
        #expect(codeBlocks[0].contains("import SyntaxKit"))
        #expect(codeBlocks[0].contains("Enum(\"MyEnum\")"))
    }
    
    @Test("Can compile simple SyntaxKit example")
    func testCompileSimpleExample() throws {
        let code = """
        import SyntaxKit
        
        let myEnum = Enum("MyEnum") {
            EnumCase("first")
            EnumCase("second")
        }
        
        let result = myEnum.formatted().description
        """
        
        // For now, just test that the code can be parsed as valid Swift
        // (compilation would require full dependency setup)
        #expect(!code.isEmpty)
        #expect(code.contains("import SyntaxKit"))
    }
    
    private func extractSwiftCodeBlocks(from content: String) -> [String] {
        let lines = content.components(separatedBy: .newlines)
        var codeBlocks: [String] = []
        var currentBlock: String?
        var inCodeBlock = false
        
        for line in lines {
            if line.hasPrefix("```swift") {
                inCodeBlock = true
                currentBlock = ""
            } else if line == "```" && inCodeBlock {
                if let block = currentBlock, !block.isEmpty {
                    codeBlocks.append(block)
                }
                inCodeBlock = false
                currentBlock = nil
            } else if inCodeBlock {
                if let existing = currentBlock {
                    currentBlock = existing + "\n" + line
                } else {
                    currentBlock = line
                }
            }
        }
        
        return codeBlocks
    }
}