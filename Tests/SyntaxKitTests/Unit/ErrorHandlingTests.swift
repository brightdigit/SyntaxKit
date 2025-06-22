import Testing

@testable import SyntaxKit

@Suite internal struct ErrorHandlingTests {
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

    #expect(
      generated.normalize() == expected.normalize()
    )

    print("Generated code:")
    print(generated)
  }

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
