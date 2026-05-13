//
//  ErrorHandlingTests.swift
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

@Suite internal struct ErrorHandlingTests {
  // swiftlint:disable function_body_length
  @Test("Error handling DSL generates expected Swift code")
  internal func testErrorHandlingExample() throws {
    let errorHandlingExample = Group {
      Variable(.var, name: "vendingMachine", equals: Init("VendingMachine"))
      Assignment("vendingMachine.coinsDeposited", Literal.integer(8))
      Do {
        Call("buyFavoriteSnack") {
          ParameterExp(name: "person", value: Literal.string("Alice"))
          ParameterExp(name: "vendingMachine", value: Literal.ref("vendingMachine"))
        }.throwing()
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Success! Yum."))
        }
      } catch: {
        Catch(EnumCase("invalidSelection")) {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Invalid Selection."))
          }
        }
        Catch(EnumCase("outOfStock")) {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Out of Stock."))
          }
        }
        Catch(
          EnumCase("insufficientFunds")
            .associatedValue("coinsNeeded", type: "Int")
        ) {
          Call("print") {
            ParameterExp(
              unlabeled: Literal.string(
                "Insufficient funds. Please insert an additional \\(coinsNeeded) coins."
              )
            )
          }
        }
        Catch {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Unexpected error: \\(error)."))
          }
        }
      }
    }

    let generated = errorHandlingExample.generateCode()
    let expected = """
      var vendingMachine = VendingMachine()
      vendingMachine.coinsDeposited = 8
      do {
      try buyFavoriteSnack(person: "Alice", vendingMachine: vendingMachine)
      print("Success! Yum.")
      } catch .invalidSelection {
      print("Invalid Selection.")
      } catch .outOfStock {
      print("Out of Stock.")
      } catch .insufficientFunds(let coinsNeeded) {
      print("Insufficient funds. Please insert an additional \\(coinsNeeded) coins.")
      } catch {
      print("Unexpected error: \\(error).")
      }
      """

    let normalizedGenerated = generated.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "\n", with: "")
    let normalizedExpected =
      expected
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "\n", with: "")
    #expect(normalizedGenerated.contains(normalizedExpected))
  }
  // swiftlint:enable function_body_length

  @Test("Function with throws clause and unlabeled parameter generates correct syntax")
  internal func testFunctionWithThrowsClauseAndUnlabeledParameter() throws {
    let function = Function("summarize") {
      Parameter(unlabeled: "ratings", type: "[Int]")
    } _: {
      Guard {
        VariableExp("ratings").property("isEmpty").not()
      } else: {
        Throw(EnumCase("noRatings"))
      }
    }.throws("StatisticsError")

    let generated = function.generateCode()
    let expected = """
      func summarize(_ ratings: [Int]) throws(StatisticsError) {
        guard !ratings.isEmpty else { throw .noRatings }
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Async functionality generates correct syntax")
  internal func testAsyncFunctionality() throws {
    let asyncCode = Group {
      Variable(.let, name: "data") {
        Call("fetchUserData") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }
      }.async()
      Variable(.let, name: "posts") {
        Call("fetchUserPosts") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }
      }.async()
      TupleAssignment(
        ["fetchedData", "fetchedPosts"],
        equals: Tuple {
          VariableExp("data")
          VariableExp("posts")
        }
      ).async().throwing()
    }

    let generated = asyncCode.generateCode()
    let expected = """
      async let data = fetchUserData(id: 1)
      async let posts = fetchUserPosts(id: 1)
      let (fetchedData, fetchedPosts) = try await (data, posts)
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
