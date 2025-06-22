import Testing

@testable import SyntaxKit

@Suite internal struct TupleAssignmentAsyncTests {
  // MARK: - Async Tuple Assignment Tests

  @Test("Async tuple assignment generates correct syntax")
  internal func testAsyncTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["data", "posts"],
      equals: Tuple {
        VariableExp("fetchData")
        VariableExp("fetchPosts")
      }
    ).async()

    let generated = tupleAssignment.generateCode()
    let expected = "let (data, posts) = await (fetchData, fetchPosts)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Async tuple assignment with mixed expressions generates correct syntax")
  internal func testAsyncTupleAssignmentWithMixedExpressions() throws {
    let tupleAssignment = TupleAssignment(
      ["result", "count"],
      equals: Tuple {
        Call("processData") {
          ParameterExp(name: "input", value: Literal.string("test"))
        }
        Literal.integer(42)
      }
    ).async()

    let generated = tupleAssignment.generateCode()
    let expected = "let (result, count) = await (processData(input: \"test\"), " + "42)"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Throwing Tuple Assignment Tests

  @Test("Throwing tuple assignment generates correct syntax")
  internal func testThrowingTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["data", "posts"],
      equals: Tuple {
        VariableExp("fetchData")
        VariableExp("fetchPosts")
      }
    ).throwing()

    let generated = tupleAssignment.generateCode()
    let expected = "let (data, posts) = try (fetchData, fetchPosts)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Throwing tuple assignment with async calls generates correct syntax")
  internal func testThrowingTupleAssignmentWithAsyncCalls() throws {
    let tupleAssignment = TupleAssignment(
      ["data", "posts"],
      equals: Tuple {
        Call("fetchUserData") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }.async()
        Call("fetchUserPosts") {
          ParameterExp(name: "id", value: Literal.integer(1))
        }.async()
      }
    ).throwing()

    let generated = tupleAssignment.generateCode()
    let expected =
      "let (data, posts) = try (await fetchUserData(id: 1), " + "await fetchUserPosts(id: 1))"

    #expect(generated.normalize() == expected.normalize())
  }

  // MARK: - Async and Throwing Tuple Assignment Tests

  @Test("Async and throwing tuple assignment generates correct syntax")
  internal func testAsyncAndThrowingTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["data", "posts"],
      equals: Tuple {
        VariableExp("fetchData")
        VariableExp("fetchPosts")
      }
    ).async().throwing()

    let generated = tupleAssignment.generateCode()
    let expected = "let (data, posts) = try await (fetchData, fetchPosts)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Async and throwing tuple assignment with complex expressions generates correct syntax")
  internal func testAsyncAndThrowingTupleAssignmentWithComplexExpressions() throws {
    let tupleAssignment = TupleAssignment(
      ["user", "profile", "settings"],
      equals: Tuple {
        Call("fetchUser") {
          ParameterExp(name: "id", value: Literal.integer(123))
        }.async()
        Call("fetchProfile") {
          ParameterExp(name: "userId", value: Literal.integer(123))
        }.async()
        Call("fetchSettings") {
          ParameterExp(name: "userId", value: Literal.integer(123))
        }.async()
      }
    ).async().throwing()

    let generated = tupleAssignment.generateCode()
    let expected =
      "let (user, profile, settings) = try await (await fetchUser(id: 123), await fetchProfile(userId: 123), await fetchSettings(userId: 123))"

    #expect(generated.normalize() == expected.normalize())
  }
}
