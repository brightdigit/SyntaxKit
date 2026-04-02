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
