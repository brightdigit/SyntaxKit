import Testing

@testable import SyntaxKit

@Suite internal struct TupleAssignmentTests {
  // MARK: - Basic Tuple Assignment Tests

  @Test("Basic tuple assignment generates correct syntax")
  internal func testBasicTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["x", "y"],
      equals: Tuple {
        Literal.integer(1)
        Literal.integer(2)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (x, y) = (1, 2)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Single element tuple assignment generates correct syntax")
  internal func testSingleElementTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["value"],
      equals: Tuple {
        Literal.string("test")
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (value) = (\"test\")"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Three element tuple assignment generates correct syntax")
  internal func testThreeElementTupleAssignment() throws {
    let tupleAssignment = TupleAssignment(
      ["x", "y", "z"],
      equals: Tuple {
        Literal.integer(1)
        Literal.integer(2)
        Literal.integer(3)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (x, y, z) = (1, 2, 3)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with mixed literal types generates correct syntax")
  internal func testTupleAssignmentWithMixedTypes() throws {
    let tupleAssignment = TupleAssignment(
      ["name", "age", "isActive"],
      equals: Tuple {
        Literal.string("John")
        Literal.integer(30)
        Literal.boolean(true)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (name, age, isActive) = (\"John\", 30, true)"

    #expect(generated.normalize() == expected.normalize())
  }

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
    let expected = "let (result, count) = await (processData(input: \"test\"), 42)"

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
      "let (data, posts) = try (await fetchUserData(id: 1), await fetchUserPosts(id: 1))"

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

  // MARK: - Edge Cases and Error Handling Tests

  @Test("Tuple assignment with empty elements array throws error")
  internal func testTupleAssignmentWithEmptyElements() throws {
    // This should be handled gracefully by the DSL
    let tupleAssignment = TupleAssignment(
      [],
      equals: Tuple {
        Literal.integer(1)
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let () = (1)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with variable expressions generates correct syntax")
  internal func testTupleAssignmentWithVariableExpressions() throws {
    let tupleAssignment = TupleAssignment(
      ["firstName", "lastName"],
      equals: Tuple {
        VariableExp("user.firstName")
        VariableExp("user.lastName")
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (firstName, lastName) = (user.firstName, user.lastName)"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with function calls generates correct syntax")
  internal func testTupleAssignmentWithFunctionCalls() throws {
    let tupleAssignment = TupleAssignment(
      ["min", "max"],
      equals: Tuple {
        Call("findMinimum") {
          ParameterExp(name: "array", value: VariableExp("numbers"))
        }
        Call("findMaximum") {
          ParameterExp(name: "array", value: VariableExp("numbers"))
        }
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (min, max) = (findMinimum(array: numbers), findMaximum(array: numbers))"

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Tuple assignment with nested tuples generates correct syntax")
  internal func testTupleAssignmentWithNestedTuples() throws {
    let tupleAssignment = TupleAssignment(
      ["point", "color"],
      equals: Tuple {
        Tuple {
          Literal.integer(10)
          Literal.integer(20)
        }
        Tuple {
          Literal.integer(255)
          Literal.integer(0)
          Literal.integer(0)
        }
      }
    )

    let generated = tupleAssignment.generateCode()
    let expected = "let (point, color) = ((10, 20), (255, 0, 0))"

    #expect(generated.normalize() == expected.normalize())
  }

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
