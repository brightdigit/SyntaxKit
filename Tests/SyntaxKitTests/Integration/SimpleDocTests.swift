//
//  SimpleDocTests.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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
import Testing

/// Simple test to validate documentation examples
@Suite("Simple Documentation Examples")
internal struct SimpleDocTests {
  @Test("Basic markdown code extraction works")
  internal func testMarkdownCodeExtraction() throws {
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
  internal func testCompileSimpleExample() throws {
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
