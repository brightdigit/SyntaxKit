//
//  ProtocolTests.swift
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

internal struct ProtocolTests {
  @Test internal func testSimpleProtocol() {
    let vehicleProtocol = Protocol("Vehicle") {
      PropertyRequirement("numberOfWheels", type: "Int", access: .get)
      PropertyRequirement("brand", type: "String", access: .getSet)
      FunctionRequirement("start")
      FunctionRequirement("stop")
      FunctionRequirement("speed", returns: "Int")
    }

    let expected = """
      protocol Vehicle {
        var numberOfWheels: Int { get }
        var brand: String { get set }
        func start()
        func stop()
        func speed() -> Int
      }
      """

    let normalizedGenerated = vehicleProtocol.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testEmptyProtocol() {
    let emptyProtocol = Protocol("EmptyProtocol") {}

    let expected = """
      protocol EmptyProtocol {
      }
      """

    let normalizedGenerated = emptyProtocol.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testProtocolWithInheritance() {
    let protocolWithInheritance = Protocol("MyProtocol") {
      PropertyRequirement("value", type: "String", access: .getSet)
    }.inherits("Equatable", "Hashable")

    let expected = """
      protocol MyProtocol: Equatable, Hashable {
        var value: String { get set }
      }
      """

    let normalizedGenerated = protocolWithInheritance.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testFunctionRequirementWithParameters() {
    let protocolWithFunction = Protocol("Calculator") {
      FunctionRequirement("add", returns: "Int") {
        Parameter(name: "a", type: "Int")
        Parameter(name: "b", type: "Int")
      }
    }

    let expected = """
      protocol Calculator {
        func add(a: Int, b: Int) -> Int
      }
      """

    let normalizedGenerated = protocolWithFunction.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testStaticFunctionRequirement() {
    let protocolWithStaticFunction = Protocol("Factory") {
      FunctionRequirement("create", returns: "Self").static()
    }

    let expected = """
      protocol Factory {
        static func create() -> Self
      }
      """

    let normalizedGenerated = protocolWithStaticFunction.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testMutatingFunctionRequirement() {
    let protocolWithMutatingFunction = Protocol("Resettable") {
      FunctionRequirement("reset").mutating()
    }

    let expected = """
      protocol Resettable {
        mutating func reset()
      }
      """

    let normalizedGenerated = protocolWithMutatingFunction.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPropertyRequirementGetOnly() {
    let propertyReq = PropertyRequirement("readOnlyProperty", type: "String", access: .get)
    let prtcl = Protocol("TestProtocol") {
      propertyReq
    }

    let expected = """
      protocol TestProtocol {
        var readOnlyProperty: String { get }
      }
      """

    let normalizedGenerated = prtcl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPropertyRequirementGetSet() {
    let propertyReq = PropertyRequirement("readWriteProperty", type: "Int", access: .getSet)
    let prtcl = Protocol("TestProtocol") {
      propertyReq
    }

    let expected = """
      protocol TestProtocol {
        var readWriteProperty: Int { get set }
      }
      """

    let normalizedGenerated = prtcl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testFunctionRequirementWithDefaultParameters() {
    let functionReq = FunctionRequirement("process", returns: "String") {
      Parameter(name: "input", type: "String")
      Parameter(name: "options", type: "ProcessingOptions", defaultValue: "ProcessingOptions()")
    }
    let prtcl = Protocol("TestProtocol") {
      functionReq
    }

    let expected = """
      protocol TestProtocol {
        func process(input: String, options: ProcessingOptions = ProcessingOptions()) -> String
      }
      """

    let normalizedGenerated = prtcl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testComplexProtocolWithMixedRequirements() {
    let complexProtocol = Protocol("ComplexProtocol") {
      PropertyRequirement("id", type: "UUID", access: .get)
      PropertyRequirement("name", type: "String", access: .getSet)
      FunctionRequirement("initialize").mutating()
      FunctionRequirement("process", returns: "Result") {
        Parameter(name: "input", type: "Data")
      }
      FunctionRequirement("factory", returns: "Self").static()
    }.inherits("Identifiable")

    let expected = """
      protocol ComplexProtocol: Identifiable {
        var id: UUID { get }
        var name: String { get set }
        mutating func initialize()
        func process(input: Data) -> Result
        static func factory() -> Self
      }
      """

    let normalizedGenerated = complexProtocol.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }
}
