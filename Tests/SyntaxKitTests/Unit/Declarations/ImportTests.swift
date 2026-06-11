//
//  ImportTests.swift
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

internal struct ImportTests {
  @Test internal func testBasicImport() {
    let importDecl = Import("Foundation")

    let generated = importDecl.generateCode()
    #expect(generated.normalize() == "import Foundation")
  }

  @Test internal func testImportWithTestableAttribute() {
    let importDecl = Import("XCTest").attribute("testable")

    let generated = importDecl.generateCode()
    // Fix 1 regression: must have a space between @testable and import
    #expect(generated.contains("@testable import"))
    #expect(!generated.contains("@testableimport"))
    #expect(generated.contains("XCTest"))
  }

  @Test internal func testImportWithGenericAttribute() {
    let importDecl = Import("Foundation").attribute("_implementationOnly")

    let generated = importDecl.generateCode()
    #expect(generated.contains("@_implementationOnly import"))
    #expect(generated.contains("Foundation"))
  }
}
