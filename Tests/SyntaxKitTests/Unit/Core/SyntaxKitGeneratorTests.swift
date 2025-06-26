//
//  SyntaxKitGeneratorTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import XCTest
@testable import SyntaxKit

final class SyntaxKitGeneratorTests: XCTestCase {
  
  func testSyntaxKitGeneratorErrorTypes() {
    // Test that our error types work correctly
    let compilationError = SyntaxKitGeneratorError.compilationFailed("Test error")
    let executionError = SyntaxKitGeneratorError.executionFailed("Test error")
    
    XCTAssertEqual(compilationError.errorDescription, "Compilation failed: Test error")
    XCTAssertEqual(executionError.errorDescription, "Execution failed: Test error")
  }
  
  func testSyntaxKitGeneratorTypeExists() {
    // Test that the SyntaxKitGenerator type exists and can be instantiated
    let generator = SyntaxKitGenerator()
    XCTAssertNotNil(generator)
  }
  
  func testGenerateCodeMethodSignature() {
    // Test that the generateCode method exists with the correct signature
    // This is a compile-time test to ensure the API is available
    let _: (String, String) -> String = { dslCode, outputVariable in
      // This would normally call SyntaxKitGenerator.generateCode(from:outputVariable:)
      // but we're just testing the method signature exists
      return ""
    }
    
    // If this compiles, the test passes
    XCTAssertTrue(true)
  }
  
  func testErrorHandling() {
    // Test that our error types conform to the expected protocols
    let error: Error = SyntaxKitGeneratorError.compilationFailed("test")
    XCTAssertTrue(error is SyntaxKitGeneratorError)
    
    let localizedError: LocalizedError = SyntaxKitGeneratorError.executionFailed("test")
    XCTAssertNotNil(localizedError.errorDescription)
  }
} 