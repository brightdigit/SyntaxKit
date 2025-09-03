//
//  TypeAliasTests.swift
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

internal struct TypeAliasTests {
  // MARK: - Basic TypeAlias Tests

  @Test internal func testBasicTypeAlias() {
    let typeAlias = TypeAlias("MappedType", equals: "String")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias MappedType = String"))
  }

  @Test internal func testTypeAliasWithComplexType() {
    let typeAlias = TypeAlias("ResultType", equals: "Result<String, Error>")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias ResultType = Result<String, Error>"))
  }

  @Test internal func testTypeAliasWithGenericType() {
    let typeAlias = TypeAlias("ArrayType", equals: "Array<Int>")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias ArrayType = Array<Int>"))
  }

  @Test internal func testTypeAliasWithOptionalType() {
    let typeAlias = TypeAlias("OptionalString", equals: "String?")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias OptionalString = String?"))
  }

  // MARK: - TypeAlias in Context Tests

  @Test internal func testTypeAliasInExtension() {
    let extensionDecl = Extension("MyEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "test", type: "MappedType", equals: Literal.ref("value"))
        .withExplicitType()
    }

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyEnum"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("let test: MappedType = value"))
  }

  @Test internal func testTypeAliasInStruct() {
    let structDecl = Struct("Container") {
      TypeAlias("ElementType", equals: "String")
      Variable(.let, name: "element", type: "ElementType").withExplicitType()
    }

    let generated = structDecl.generateCode().normalize()

    #expect(generated.contains("struct Container"))
    #expect(generated.contains("typealias ElementType = String"))
    #expect(generated.contains("let element: ElementType"))
  }

  @Test internal func testTypeAliasInEnum() {
    let enumDecl = Enum("Result") {
      TypeAlias("SuccessType", equals: "String")
      TypeAlias("FailureType", equals: "Error")
      EnumCase("success")
      EnumCase("failure")
    }

    let generated = enumDecl.generateCode().normalize()

    #expect(generated.contains("enum Result"))
    #expect(generated.contains("typealias SuccessType = String"))
    #expect(generated.contains("typealias FailureType = Error"))
    #expect(generated.contains("case success"))
    #expect(generated.contains("case failure"))
  }

  // MARK: - Edge Cases

  @Test internal func testTypeAliasWithSpecialCharacters() {
    let typeAlias = TypeAlias("GenericType<T>", equals: "Array<T>")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias GenericType<T> = Array<T>"))
  }

  @Test internal func testTypeAliasWithProtocolComposition() {
    let typeAlias = TypeAlias("ProtocolType", equals: "Protocol1 & Protocol2")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias ProtocolType = Protocol1 & Protocol2"))
  }

  @Test internal func testTypeAliasWithFunctionType() {
    let typeAlias = TypeAlias("Handler", equals: "(String) -> Void")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias Handler = (String) -> Void"))
  }

  @Test internal func testTypeAliasWithTupleType() {
    let typeAlias = TypeAlias("Coordinate", equals: "(x: Double, y: Double)")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias Coordinate = (x: Double, y: Double)"))
  }

  @Test internal func testTypeAliasWithClosureType() {
    let typeAlias = TypeAlias("Callback", equals: "@escaping (Result<String, Error>) -> Void")
    let generated = typeAlias.generateCode().normalize()

    #expect(generated.contains("typealias Callback = @escaping (Result<String, Error>) -> Void"))
  }

  // MARK: - Integration Tests

  @Test internal func testTypeAliasWithStaticVariable() {
    let extensionDecl = Extension("MyEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: ["a", "b", "c"]).withExplicitType().static()
    }.inherits("MappedValueRepresentable")

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyEnum: MappedValueRepresentable"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [String] = [\"a\", \"b\", \"c\"]"))
  }

  @Test internal func testTypeAliasWithDictionaryVariable() {
    let extensionDecl = Extension("MyEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: [1: "a", 2: "b"]).withExplicitType().static()
    }.inherits("MappedValueRepresentable")

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension MyEnum: MappedValueRepresentable"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [Int: String]"))
    #expect(generated.contains("1: \"a\""))
    #expect(generated.contains("2: \"b\""))
  }
}
