//
//  AttributeTests.swift
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
import SyntaxKit
import Testing

@Suite internal struct AttributeTests {
  @Test("Class with attribute generates correct syntax")
  internal func testClassWithAttribute() throws {
    let classDecl = Class("Foo") {
      Variable(.var, name: "bar", type: "String", equals: "bar")
    }.attribute("objc")

    let generated = classDecl.syntax.description
    #expect(generated.contains("@objc"))
    #expect(generated.contains("class Foo"))
  }

  @Test("Function with attribute generates correct syntax")
  internal func testFunctionWithAttribute() throws {
    let function = Function("bar") {
      Variable(.let, name: "message", type: "String", equals: "bar")
    }.attribute("available")

    let generated = function.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("func bar"))
  }

  @Test("Variable with attribute generates correct syntax")
  internal func testVariableWithAttribute() throws {
    let variable = Variable(.var, name: "bar", type: "String", equals: "bar")
      .attribute("Published")

    let generated = variable.syntax.description
    #expect(generated.contains("@Published"))
    #expect(generated.contains("var bar"))
  }

  @Test("Multiple attributes on class generates correct syntax")
  internal func testMultipleAttributesOnClass() throws {
    let classDecl = Class("Foo") {
      Variable(.var, name: "bar", type: "String", equals: "bar")
    }
    .attribute("objc")
    .attribute("MainActor")

    let generated = classDecl.syntax.description
    #expect(generated.contains("@objc"))
    #expect(generated.contains("@MainActor"))
    #expect(generated.contains("class Foo"))
  }

  @Test("Attribute with arguments generates correct syntax")
  internal func testAttributeWithArguments() throws {
    let attribute = Attribute("available", arguments: ["iOS", "17.0", "*"])

    let generated = attribute.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS"))
    #expect(generated.contains("17.0"))
    #expect(generated.contains("*"))
  }

  @Test("Attribute with single argument generates correct syntax")
  internal func testAttributeWithSingleArgument() throws {
    let attribute = Attribute("available", argument: "iOS 17.0")

    let generated = attribute.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS 17.0"))
  }

  @Test("Comprehensive attribute example generates correct syntax")
  internal func testComprehensiveAttributeExample() throws {
    let classDecl = Class("Foo") {
      Variable(.var, name: "bar", type: "String", equals: "bar")
        .attribute("Published")

      Function("bar") {
        Variable(.let, name: "message", type: "String", equals: "bar")
      }
      .attribute("available")
      .attribute("MainActor")

      Function("baz") {
        Variable(.let, name: "message", type: "String", equals: "baz")
      }
      .attribute("MainActor")
    }.attribute("objc")

    let generated = classDecl.syntax.description
    #expect(generated.contains("@objc"))
    #expect(generated.contains("@Published"))
    #expect(generated.contains("@available"))
    #expect(generated.contains("@MainActor"))
    #expect(generated.contains("class Foo"))
    #expect(generated.contains("var bar"))
    #expect(generated.contains("func bar"))
    #expect(generated.contains("func baz"))
  }

  @Test("Function with attribute arguments generates correct syntax")
  internal func testFunctionWithAttributeArguments() throws {
    let function = Function("bar") {
      Variable(.let, name: "message", type: "String", equals: "bar")
    }.attribute("available", arguments: ["iOS", "17.0", "*"])

    let generated = function.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS"))
    #expect(generated.contains("17.0"))
    #expect(generated.contains("*"))
    #expect(generated.contains("func bar"))
  }

  @Test("Class with attribute arguments generates correct syntax")
  internal func testClassWithAttributeArguments() throws {
    let classDecl = Class("Foo") {
      Variable(.var, name: "bar", type: "String", equals: "bar")
    }.attribute("available", arguments: ["iOS", "17.0"])

    let generated = classDecl.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS"))
    #expect(generated.contains("17.0"))
    #expect(generated.contains("class Foo"))
  }

  @Test("Variable with attribute arguments generates correct syntax")
  internal func testVariableWithAttributeArguments() throws {
    let variable = Variable(.var, name: "bar", type: "String", equals: "bar")
      .attribute("available", arguments: ["iOS", "17.0"])

    let generated = variable.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS"))
    #expect(generated.contains("17.0"))
    #expect(generated.contains("var bar"))
  }

  @Test("Parameter with attribute generates correct syntax")
  internal func testParameterWithAttribute() throws {
    let function = Function("process") {
      Parameter(name: "data", type: "Data")
        .attribute("escaping")
    } _: {
      Variable(.let, name: "result", type: "String", equals: "processed")
    }

    let generated = function.syntax.description
    #expect(generated.contains("@escaping"))
    #expect(generated.contains("data : Data"))
    #expect(generated.contains("func process"))
  }

  @Test("Parameter with attribute arguments generates correct syntax")
  internal func testParameterWithAttributeArguments() throws {
    let function = Function("validate") {
      Parameter(name: "input", type: "String")
        .attribute("available", arguments: ["iOS", "17.0"])
    } _: {
      Variable(.let, name: "result", type: "Bool", equals: "true")
    }

    let generated = function.syntax.description
    #expect(generated.contains("@available"))
    #expect(generated.contains("iOS"))
    #expect(generated.contains("17.0"))
    #expect(generated.contains("input : String"))
    #expect(generated.contains("func validate"))
  }
}
