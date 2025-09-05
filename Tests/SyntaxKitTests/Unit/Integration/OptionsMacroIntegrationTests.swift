//
//  OptionsMacroIntegrationTests.swift
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

internal struct OptionsMacroIntegrationTests {
  // MARK: - Enum with Raw Values (Dictionary) Tests

  @Test internal func testEnumWithRawValuesCreatesDictionary() {
    // Simulate the Options macro expansion for an enum with raw values
    let keyValues: [Int: String] = [2: "a", 5: "b", 6: "c", 12: "d"]

    let extensionDecl = Extension("MockDictionaryEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: keyValues).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains(
        "extension MockDictionaryEnum: MappedValueRepresentable, MappedValueRepresented"
      )
    )
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [Int: String]"))
    #expect(generated.contains("2: \"a\""))
    #expect(generated.contains("5: \"b\""))
    #expect(generated.contains("6: \"c\""))
    #expect(generated.contains("12: \"d\""))
  }

  @Test internal func testEnumWithoutRawValuesCreatesArray() {
    // Simulate the Options macro expansion for an enum without raw values
    let caseNames: [String] = ["red", "green", "blue"]

    let extensionDecl = Extension("Color") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: caseNames).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(generated.contains("extension Color: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(
      generated.contains("static let mappedValues: [String] = [\"red\", \"green\", \"blue\"]"))
  }

  // MARK: - Complex Integration Tests

  @Test internal func testCompleteOptionsMacroWorkflow() {
    // This test demonstrates the complete workflow that the Options macro would use
    // for an enum WITH raw values

    let enumName = "TestEnum"

    // Create the mappedValues variable for enum with raw values
    let keyValues: [Int: String] = [1: "first", 2: "second", 3: "third"]
    let mappedValuesVariable = Variable(.let, name: "mappedValues", equals: keyValues)
      .withExplicitType().static()

    // Create the extension
    let extensionDecl = Extension(enumName) {
      TypeAlias("MappedType", equals: "String")
      mappedValuesVariable
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    // Verify the complete extension
    #expect(
      generated.contains("extension TestEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [Int: String]"))
    #expect(generated.contains("1: \"first\""))
    #expect(generated.contains("2: \"second\""))
    #expect(generated.contains("3: \"third\""))
  }

  @Test internal func testOptionsMacroWorkflowWithoutRawValues() {
    // Test the workflow for enums without raw values

    let enumName = "SimpleEnum"

    // Create the mappedValues variable for enum without raw values
    let caseNames: [String] = ["first", "second"]
    let mappedValuesVariable = Variable(.let, name: "mappedValues", equals: caseNames)
      .withExplicitType().static()

    let extensionDecl = Extension(enumName) {
      TypeAlias("MappedType", equals: "String")
      mappedValuesVariable
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains("extension SimpleEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [String] = [\"first\", \"second\"]"))
  }

  // MARK: - Edge Cases

  @Test internal func testEmptyEnumCases() {
    let caseNames: [String] = []

    let extensionDecl = Extension("EmptyEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: caseNames).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains("extension EmptyEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [String] = []"))
  }

  @Test internal func testEmptyDictionary() {
    let keyValues: [Int: String] = [:]

    let extensionDecl = Extension("EmptyDictEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: keyValues).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains(
        "extension EmptyDictEnum: MappedValueRepresentable, MappedValueRepresented"
      )
    )
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [Int: String] = [: ]"))
  }

  @Test internal func testSpecialCharactersInCaseNames() {
    let caseNames: [String] = ["case_with_underscore", "case-with-dash", "caseWithCamelCase"]

    let extensionDecl = Extension("SpecialEnum") {
      TypeAlias("MappedType", equals: "String")
      Variable(.let, name: "mappedValues", equals: caseNames).withExplicitType().static()
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    let generated = extensionDecl.generateCode().normalize()

    #expect(
      generated.contains("extension SpecialEnum: MappedValueRepresentable, MappedValueRepresented"))
    #expect(generated.contains("typealias MappedType = String"))
    #expect(generated.contains("static let mappedValues: [String]"))
    #expect(generated.contains("\"case_with_underscore\""))
    #expect(generated.contains("\"case-with-dash\""))
    #expect(generated.contains("\"caseWithCamelCase\""))
  }
}
