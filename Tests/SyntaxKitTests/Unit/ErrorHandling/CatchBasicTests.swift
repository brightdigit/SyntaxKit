//
//  CatchBasicTests.swift
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

@Suite internal struct CatchBasicTests {
  // MARK: - Basic Catch Tests

  @Test("Basic catch without pattern generates correct syntax")
  internal func testBasicCatchWithoutPattern() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("An error occurred"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch { print(\"An error occurred\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with enum case pattern generates correct syntax")
  internal func testCatchWithEnumCasePattern() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Connection failed"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed { print(\"Connection failed\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with enum case and associated value generates correct syntax")
  internal func testCatchWithEnumCaseAndAssociatedValue() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("invalidInput").associatedValue("fieldName", type: "String")) {
        Call("print") {
          ParameterExp(
            unlabeled: Literal.string("Invalid input for field: \\(fieldName)")
          )
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .invalidInput(let fieldName) { print(\"Invalid input for field: \\(fieldName)\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Catch with Different Pattern Types

  @Test("Catch with multiple enum cases generates correct syntax")
  internal func testCatchWithMultipleEnumCases() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("timeout")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Request timed out"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .timeout { print(\"Request timed out\") }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with error binding generates correct syntax")
  internal func testCatchWithErrorBinding() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch {
        Call("logError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
        Call("print") {
          ParameterExp(
            unlabeled: Literal.string("Error: \\(error)")
          )
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected =
      "do { try someFunction(param: \"test\") } catch { " + "logError(error: error) "
      + "print(\"Error: \\(error)\") }"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with specific error type generates correct syntax")
  internal func testCatchWithSpecificErrorType() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("CustomError")) {
        Call("handleCustomError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .CustomError { handleCustomError(error: error) }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
