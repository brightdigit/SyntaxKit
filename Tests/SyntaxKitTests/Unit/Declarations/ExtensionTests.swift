//
//  ExtensionTests.swift
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

import Foundation
import Testing

@testable import SyntaxKit

internal struct ExtensionTests {
  // MARK: - Basic Extension Tests

  @Test internal func testBasicExtension() {
    let extensionDecl = Extension("String") {
      Variable(.let, name: "test", type: "Int", equals: Literal.integer(42)).withExplicitType()
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension String"))
    #expect(generated.contains("let test: Int = 42"))
  }

  @Test internal func testExtensionWithMultipleMembers() {
    let extensionDecl = Extension("Array") {
      Variable(.let, name: "isEmpty", type: "Bool", equals: Literal.boolean(true))
        .withExplicitType()
      Variable(.let, name: "count", type: "Int", equals: Literal.integer(0)).withExplicitType()
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension Array"))
    #expect(generated.contains("let isEmpty: Bool = true"))
    #expect(generated.contains("let count: Int = 0"))
  }

  // MARK: - Extension with Inheritance Tests

  @Test internal func testExtensionWithSingleInheritance() {
    let extensionDecl = Extension("MyEnum") {
      TypeAlias("MappedType", equals: "String")
    }.inherits("MappedValueRepresentable")

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyEnum: MappedValueRepresentable"))
    #expect(generated.contains("typealias MappedType = String"))
  }

  @Test internal func testExtensionWithMultipleInheritance() {
    let extensionDecl = Extension("MyEnum") {
      TypeAlias("MappedType", equals: "String")
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains("extension MyEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
  }

  @Test internal func testExtensionWithoutInheritance() {
    let extensionDecl = Extension("MyType") {
      Variable(.let, name: "constant", type: "String", equals: Literal.ref("value"))
        .withExplicitType()
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyType"))
    #expect(!generated.contains("extension MyType:"))
    #expect(generated.contains("let constant: String = value"))
  }

  // MARK: - Extension with Complex Members Tests

  @Test internal func testExtensionWithStaticVariables() {
    let array: [String] = ["a", "b", "c"]
    let dict: [Int: String] = [1: "one", 2: "two"]

    let extensionDecl = Extension("TestEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: array).withExplicitType().static()
      Variable(.let, name: "lookup", equals: dict).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains("extension TestEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [String] = [\"a\", \"b\", \"c\"]"))
    #expect(generated.contains("static let lookup: [Int: String]"))
    #expect(generated.contains("1: \"one\""))
    #expect(generated.contains("2: \"two\""))
  }

  @Test internal func testExtensionWithFunctions() {
    let extensionDecl = Extension("String") {
      Function("uppercasedFirst", returns: "String") {
        Return {
          VariableExp("self.prefix(1).uppercased() + self.dropFirst()")
        }
      }
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension String"))
    #expect(generated.contains("func uppercasedFirst() -> String"))
    #expect(generated.contains("return self.prefix(1).uppercased() + self.dropFirst()"))
  }

  // MARK: - Edge Cases

  @Test internal func testExtensionWithEmptyBody() {
    let extensionDecl = Extension("EmptyType") {
      // Empty body
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension EmptyType"))
    #expect(generated.contains("{"))
    #expect(generated.contains("}"))
  }

  @Test internal func testExtensionWithSpecialCharactersInName() {
    let extensionDecl = Extension("MyType<T>") {
      Variable(.let, name: "generic", type: "T", equals: Literal.nil).withExplicitType()
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyType<T>"))
    #expect(generated.contains("let generic: T = nil"))
  }

  @Test internal func testInheritsMethodReturnsNewInstance() {
    let original = Extension("Test") {
      Variable(.let, name: "value", type: "Int", equals: Literal.integer(42)).withExplicitType()
    }

    let withInheritance = original.inherits("Protocol1", "Protocol2")

    // Should be different instances
    #expect(original.generateCode() != withInheritance.generateCode())

    // Original should not have inheritance
    let originalGenerated = original.generateCode().normalize()
    #expect(!originalGenerated.contains("extension Test:"))

    // With inheritance should have inheritance
    let inheritedGenerated = withInheritance.generateCode().normalize()
    #expect(inheritedGenerated.contains(": Protocol1, Protocol2"))
  }
}
