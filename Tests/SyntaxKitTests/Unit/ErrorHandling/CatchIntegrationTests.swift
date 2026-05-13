//
//  CatchIntegrationTests.swift
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

@Suite internal struct CatchIntegrationTests {
  // MARK: - Integration Tests

  @Test("Catch in do-catch statement generates correct syntax")
  internal func testCatchInDoCatchStatement() throws {
    let doCatch = Do {
      Call("fetchData") {
        ParameterExp(name: "id", value: Literal.integer(123))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Connection failed"))
        }
      }
      Catch(EnumCase("invalidId")) {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Invalid ID"))
        }
      }
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Unexpected error: \\(error)"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try fetchData(id: 123)
      } catch .connectionFailed {
        print("Connection failed")
      } catch .invalidId {
        print("Invalid ID")
      } catch {
        print("Unexpected error: \\(error)")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with async operations generates correct syntax")
  internal func testCatchWithAsyncOperations() throws {
    let doCatch = Do {
      Variable(.let, name: "data") {
        Call("fetchData") {
          ParameterExp(name: "id", value: Literal.integer(123))
        }
      }.async()
    } catch: {
      Catch(EnumCase("timeout")) {
        Variable(.let, name: "fallbackData") {
          Call("fetchFallbackData") {
            ParameterExp(name: "id", value: Literal.integer(123))
          }
        }.async()
      }
      Catch {
        Call("logError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        async let data = fetchData(id: 123)
      } catch .timeout {
        async let fallbackData = fetchFallbackData(id: 123)
      } catch {
        logError(error: error)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with error recovery generates correct syntax")
  internal func testCatchWithErrorRecovery() throws {
    let doCatch = Do {
      Call("processUserData") {
        ParameterExp(name: "user", value: VariableExp("user"))
      }.throwing()
    } catch: {
      Catch(
        EnumCase("missingField")
          .associatedValue("fieldName", type: "String")
      ) {
        Call("setDefaultValue") {
          ParameterExp(name: "field", value: VariableExp("fieldName"))
        }
        Call("processUserData") {
          ParameterExp(name: "user", value: VariableExp("user"))
        }.throwing()
      }
      Catch {
        Call("handleUnexpectedError") {
          ParameterExp(name: "error", value: VariableExp("error"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try processUserData(user: user)
      } catch .missingField(let fieldName) {
        setDefaultValue(field: fieldName)
        try processUserData(user: user)
      } catch {
        handleUnexpectedError(error: error)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
