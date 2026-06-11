//
//  OptionsMacroIntegrationTestsAPI.swift
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

@testable import SyntaxKit

internal struct OptionsMacroIntegrationTestsAPI {
  // MARK: - API Validation Tests

  @Test internal func testNewSyntaxKitAPICompleteness() {
    // Verify that all the new API components work together correctly

    // Test LiteralValue protocol
    let array: [String] = ["a", "b", "c"]
    #expect(array.typeName == "[String]")
    #expect(array.literalString == "[\"a\", \"b\", \"c\"]")

    let dict: [Int: String] = [1: "a", 2: "b"]
    #expect(dict.typeName == "[Int: String]")
    #expect(dict.literalString.contains("1: \"a\""))
    #expect(dict.literalString.contains("2: \"b\""))

    // Test Variable with static support
    let staticVar = Variable(.let, name: "test", equals: array).withExplicitType().static()
    let staticGenerated = staticVar.generateCode().normalize()
    #expect(staticGenerated.contains("static let test: [String] = [\"a\", \"b\", \"c\"]"))

    // Test Extension with inheritance
    let ext = Extension("Test") {
      // Empty content
    }.inherits("Protocol1", "Protocol2")

    let extGenerated = ext.generateCode().normalize()
    #expect(extGenerated.contains("extension Test: Protocol1, Protocol2"))

    // Test TypeAlias
    let alias = TypeAlias("MyType", equals: "String")
    let aliasGenerated = alias.generateCode().normalize()
    #expect(aliasGenerated.contains("typealias MyType = String"))
  }
}
