//
//  CallTests.swift
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

@Suite internal struct CallTests {
  @Test("Call without parameters generates correct syntax")
  internal func testCallWithoutParameters() throws {
    let call = Call("print")
    let generated = call.generateCode()
    #expect(generated.contains("print()"))
  }

  @Test("Call with string parameter generates correct syntax")
  internal func testCallWithStringParameter() throws {
    let call = Call("print") {
      ParameterExp(name: "", value: "\"Hello, World!\"")
    }
    let generated = call.generateCode()
    #expect(generated.contains("print(\"Hello, World!\")"))
  }

  @Test("Call with named parameter generates correct syntax")
  internal func testCallWithNamedParameter() throws {
    let call = Call("function") {
      ParameterExp(name: "value", value: "42")
    }
    let generated = call.generateCode()
    #expect(generated.contains("function(value:42)"))
  }

  @Test("Call with multiple parameters generates correct syntax")
  internal func testCallWithMultipleParameters() throws {
    let call = Call("print") {
      ParameterExp(name: "", value: "\"Count:\"")
      ParameterExp(name: "count", value: "5")
    }
    let generated = call.generateCode()
    #expect(generated.contains("print(\"Count:\", count:5)"))
  }

  @Test("Call with string interpolation generates correct syntax")
  internal func testCallWithStringInterpolation() throws {
    let call = Call("print") {
      ParameterExp(name: "", value: "\"Starting \\(brand) vehicle...\"")
    }
    let generated = call.generateCode()
    #expect(generated.contains("print(\"Starting \\(brand) vehicle...\")"))
  }

  @Test("Call in function body generates correct syntax")
  internal func testCallInFunctionBody() throws {
    let function = Function("test") {
      Call("print") {
        ParameterExp(name: "", value: "\"Hello\"")
      }
    }
    let generated = function.generateCode()
    #expect(generated.contains("func test"))
    #expect(generated.contains("print(\"Hello\")"))
  }

  @Test("Protocol extension with Call generates correct syntax")
  internal func testProtocolExtensionWithCall() throws {
    let extSyntax = Extension("Vehicle") {
      Function("start") {
        Call("print") {
          ParameterExp(name: "", value: "\"Starting \\(brand) vehicle...\"")
        }
      }
    }
    let generated = extSyntax.generateCode()
    #expect(generated.contains("extension Vehicle"))
    #expect(generated.contains("func start"))
    #expect(generated.contains("print(\"Starting \\(brand) vehicle...\")"))
  }

  @Test("Struct with Call in method generates correct syntax")
  internal func testStructWithCallInMethod() throws {
    let structExp = Struct("Car") {
      Function("start") {
        Call("print") {
          ParameterExp(name: "", value: "\"Starting \\(brand) car engine...\"")
        }
      }
    }
    let generated = structExp.generateCode()
    #expect(generated.contains("struct Car"))
    #expect(generated.contains("func start"))
    #expect(generated.contains("print(\"Starting \\(brand) car engine...\")"))
  }
}
