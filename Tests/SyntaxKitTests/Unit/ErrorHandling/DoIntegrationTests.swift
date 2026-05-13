//
//  DoIntegrationTests.swift
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

@Suite internal struct DoIntegrationTests {
  // MARK: - Integration Tests

  @Test("Do statement in function generates correct syntax")
  internal func testDoStatementInFunction() throws {
    let function = Function("processData") {
      Parameter(name: "input", type: "[Int]")
    } _: {
      Do {
        Call("validateInput") {
          ParameterExp(name: "data", value: VariableExp("input"))
        }.throwing()
        Call("processValidData") {
          ParameterExp(name: "data", value: VariableExp("input"))
        }
      } catch: {
        Catch {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Validation failed"))
          }
        }
      }
    }

    let generated = function.generateCode()
    let expected = """
      func processData(input: [Int]) {
        do {
          try validateInput(data: input)
          processValidData(data: input)
        } catch {
          print("Validation failed")
        }
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with async function generates correct syntax")
  internal func testDoStatementWithAsyncFunction() throws {
    let function = Function("fetchUserData") {
      Parameter(name: "userId", type: "Int")
    } _: {
      Do {
        Variable(.let, name: "user") {
          Call("fetchUser") {
            ParameterExp(name: "id", value: VariableExp("userId"))
          }
        }.async()
        Variable(.let, name: "profile") {
          Call("fetchProfile") {
            ParameterExp(name: "userId", value: VariableExp("userId"))
          }
        }.async()
        Call("combineUserData") {
          ParameterExp(name: "user", value: VariableExp("user"))
          ParameterExp(name: "profile", value: VariableExp("profile"))
        }
      } catch: {
        Catch {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Failed to fetch user data"))
          }
        }
      }
    }.async()

    let generated = function.generateCode()
    let expected = """
      func fetchUserData(userId: Int) async {
        do {
          async let user = fetchUser(id: userId)
          async let profile = fetchProfile(userId: userId)
          combineUserData(user: user, profile: profile)
        } catch {
          print("Failed to fetch user data")
        }
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
