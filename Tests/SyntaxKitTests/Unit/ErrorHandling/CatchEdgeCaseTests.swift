//
//  CatchEdgeCaseTests.swift
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

@Suite internal struct CatchEdgeCaseTests {
  // MARK: - Edge Cases

  @Test("Catch with empty body generates correct syntax")
  internal func testCatchWithEmptyBody() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("ignored")) {
        // Empty body
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .ignored { }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with single statement generates correct syntax")
  internal func testCatchWithSingleStatement() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Call("retry") {
          ParameterExp(name: "maxAttempts", value: Literal.integer(1))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed { retry(maxAttempts: 1) }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with function call and variable assignment generates correct syntax")
  internal func testCatchWithFunctionCallAndVariableAssignment() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("invalidInput")) {
        Variable(.let, name: "errorMessage", equals: Literal.string("Invalid input"))
        Call("logError") {
          ParameterExp(name: "message", value: VariableExp("errorMessage"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .invalidInput {
        let errorMessage = "Invalid input"
        logError(message: errorMessage)
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Catch with conditional logic generates correct syntax")
  internal func testCatchWithConditionalLogic() throws {
    let doCatch = Do {
      Call("someFunction") {
        ParameterExp(name: "param", value: Literal.string("test"))
      }.throwing()
    } catch: {
      Catch(EnumCase("connectionFailed")) {
        Variable(.let, name: "retryCount", equals: Literal.integer(0))
        Call("checkRetryCount") {
          ParameterExp(name: "count", value: VariableExp("retryCount"))
        }
        Call("showError") {
          ParameterExp(name: "message", value: Literal.string("Max retries exceeded"))
        }
      }
    }

    let generated = doCatch.generateCode()
    let expected = """
      do {
        try someFunction(param: "test")
      } catch .connectionFailed {
        let retryCount = 0
        checkRetryCount(count: retryCount)
        showError(message: "Max retries exceeded")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
