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
