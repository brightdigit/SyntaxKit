//
//  AttributeTests+Arguments.swift
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
import SyntaxKit
import Testing

extension AttributeTests {
  @Suite("Arguments") internal struct Arguments {
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

    @Test("Struct with quoted string attribute argument generates string literal, not identifier")
    internal func testStructWithStringLiteralAttributeArgument() throws {
      // Fix 3 regression: "\"App Model\"" must produce @Suite("App Model"), not @Suite(App Model)
      let structDecl = Struct("AppModelTests") {}
        .attribute("Suite", arguments: ["\"App Model\""])

      let generated = structDecl.syntax.description
      #expect(
        generated.contains("@Suite(\"App Model\")") || generated.contains("@Suite( \"App Model\")"))
      #expect(!generated.contains("@Suite(App Model)"))
    }

    @Test("Function with quoted string attribute argument generates string literal")
    internal func testFunctionWithStringLiteralAttributeArgument() throws {
      // Fix 3 regression: quoted argument must produce string literal token
      let function = Function("initialCount") {}
        .attribute("Test", arguments: ["\"Initial count is zero\""])

      let generated = function.syntax.description
      // The argument should be a string literal: @Test("Initial count is zero")
      #expect(
        generated.contains("@Test(\"Initial count is zero\")")
          || generated.contains("@Test( \"Initial count is zero\")"))
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
}
