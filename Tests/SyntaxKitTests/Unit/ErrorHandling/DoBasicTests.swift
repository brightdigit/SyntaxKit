//
//  DoBasicTests.swift
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

@Suite internal struct DoBasicTests {
  // MARK: - Basic Do Tests

  @Test("Basic do statement generates correct syntax")
  internal func testBasicDoStatement() throws {
    let doStatement = Do {
      Call("print") {
        ParameterExp(unlabeled: Literal.string("Hello, World!"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error occurred"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        print("Hello, World!")
      } catch {
        print("Error occurred")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with multiple statements generates correct syntax")
  internal func testDoStatementWithMultipleStatements() throws {
    let doStatement = Do {
      Variable(.let, name: "message", equals: Literal.string("Hello"))
      Call("print") {
        ParameterExp(unlabeled: VariableExp("message"))
      }
      Call("logMessage") {
        ParameterExp(name: "text", value: VariableExp("message"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error occurred"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let message = "Hello"
        print(message)
        logMessage(text: message)
      } catch {
        print("Error occurred")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with throwing function generates correct syntax")
  internal func testDoStatementWithThrowingFunction() throws {
    let doStatement = Do {
      Call("fetchData") {
        ParameterExp(name: "id", value: Literal.integer(123))
      }.throwing()
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Failed to fetch data"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        try fetchData(id: 123)
      } catch {
        print("Failed to fetch data")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
