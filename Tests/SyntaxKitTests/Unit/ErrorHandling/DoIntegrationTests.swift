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
