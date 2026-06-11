//
//  TupleAssignmentIntegrationTests.swift
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

@Suite internal struct TupleAssignmentIntegrationTests {
  // MARK: - Integration Tests

  @Test("Tuple assignment in a function generates correct syntax")
  internal func testTupleAssignmentInFunction() throws {
    let function = Function("processData") {
      Parameter(name: "input", type: "[Int]")
    } _: {
      TupleAssignment(
        ["sum", "count"],
        equals: Tuple {
          Call("calculateSum") {
            ParameterExp(name: "numbers", value: VariableExp("input"))
          }
          Call("calculateCount") {
            ParameterExp(name: "numbers", value: VariableExp("input"))
          }
        }
      )
      Call("print") {
        ParameterExp(
          unlabeled: Literal.string("Sum: \\(sum), Count: \\(count)")
        )
      }
    }

    let generated = function.generateCode()
    let expected = """
      func processData(input: [Int]) {
        let (sum, count) = (calculateSum(numbers: input), calculateCount(numbers: input))
        print("Sum: \\(sum), Count: \\(count)")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Async tuple assignment in async function generates correct syntax")
  internal func testAsyncTupleAssignmentInAsyncFunction() throws {
    let function = Function("fetchUserData") {
      Parameter(name: "userId", type: "Int")
    } _: {
      TupleAssignment(
        ["user", "posts"],
        equals: Tuple {
          Call("fetchUser") {
            ParameterExp(name: "id", value: VariableExp("userId"))
          }.async()
          Call("fetchPosts") {
            ParameterExp(name: "userId", value: VariableExp("userId"))
          }.async()
        }
      ).async().throwing()
      Call("print") {
        ParameterExp(
          unlabeled: Literal.string("User: \\(user.name), Posts: \\(posts.count)")
        )
      }
    }.async().throws("NetworkError")

    let generated = function.generateCode()
    let expected = """
      func fetchUserData(userId: Int) async throws(NetworkError) {
        let (user, posts) = try await (await fetchUser(id: userId), await fetchPosts(userId: userId))
        print("User: \\(user.name), Posts: \\(posts.count)")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("AsyncSet tuple assignment generates concurrent async let pattern")
  internal func testAsyncSetTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["data", "posts"],
      equals: Tuple {
        Call("fetchUserData") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }
        Call("fetchUserPosts") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }
      }
    ).asyncSet().throwing()

    let generated = tupleAssignment.generateCode()
    let expected = """
      async let (data, posts) = try await (fetchUserData(id: 1), fetchUserPosts(id: 1))
      """
    #expect(generated.normalize() == expected.normalize())
  }
}
