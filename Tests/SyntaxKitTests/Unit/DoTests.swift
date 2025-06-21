import Testing

@testable import SyntaxKit

@Suite internal struct DoTests {
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

  // MARK: - Do with Complex Body

  @Test("Do statement with variable declarations generates correct syntax")
  internal func testDoStatementWithVariableDeclarations() throws {
    let doStatement = Do {
      Variable(.let, name: "user", equals: Literal.string("John"))
      Variable(.let, name: "age", equals: Literal.integer(30))
      Variable(.let, name: "isActive", equals: Literal.boolean(true))
      Call("processUser") {
        ParameterExp(name: "name", value: VariableExp("user"))
        ParameterExp(name: "age", value: VariableExp("age"))
        ParameterExp(name: "active", value: VariableExp("isActive"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error processing user"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let user = "John"
        let age = 30
        let isActive = true
        processUser(name: user, age: age, active: isActive)
      } catch {
        print("Error processing user")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with async operations generates correct syntax")
  internal func testDoStatementWithAsyncOperations() throws {
    let doStatement = Do {
      Variable(.let, name: "data") {
        Call("fetchData") {
          ParameterExp(name: "id", value: Literal.integer(123))
        }
      }.async()
      Variable(.let, name: "posts") {
        Call("fetchPosts") {
          ParameterExp(name: "userId", value: Literal.integer(123))
        }
      }.async()
      Call("processResults") {
        ParameterExp(name: "data", value: VariableExp("data"))
        ParameterExp(name: "posts", value: VariableExp("posts"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error in async operations"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        async let data = fetchData(id: 123)
        async let posts = fetchPosts(userId: 123)
        processResults(data: data, posts: posts)
      } catch {
        print("Error in async operations")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with control flow generates correct syntax")
  internal func testDoStatementWithControlFlow() throws {
    let doStatement = Do {
      Variable(.let, name: "count", equals: Literal.integer(5))
      Call("checkCount") {
        ParameterExp(name: "value", value: VariableExp("count"))
      }
      Call("print") {
        ParameterExp(unlabeled: Literal.string("Count processed"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error in control flow"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let count = 5
        checkCount(value: count)
        print("Count processed")
      } catch {
        print("Error in control flow")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

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

  // MARK: - Edge Cases

  @Test("Do statement with empty body generates correct syntax")
  internal func testDoStatementWithEmptyBody() throws {
    let doStatement = Do {
      // Empty body
    } catch: {
      Catch {
        // Empty catch
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
      } catch {
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with single expression generates correct syntax")
  internal func testDoStatementWithSingleExpression() throws {
    let doStatement = Do {
      VariableExp("someVariable")
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        someVariable
      } catch {
        print("Error")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with function call and variable assignment generates correct syntax")
  internal func testDoStatementWithFunctionCallAndVariableAssignment() throws {
    let doStatement = Do {
      Variable(.let, name: "result", equals: Literal.integer(42))
      Call("processResult") {
        ParameterExp(name: "value", value: VariableExp("result"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error processing result"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let result = 42
        processResult(value: result)
      } catch {
        print("Error processing result")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with nested do statement generates correct syntax")
  internal func testDoStatementWithNestedDoStatement() throws {
    let doStatement = Do {
      Call("outerFunction") {
        ParameterExp(name: "param", value: Literal.string("outer"))
      }
      Do {
        Call("innerFunction") {
          ParameterExp(name: "param", value: Literal.string("inner"))
        }
      } catch: {
        Catch {
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Inner error"))
          }
        }
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Outer error"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        outerFunction(param: "outer")
        do {
          innerFunction(param: "inner")
        } catch {
          print("Inner error")
        }
      } catch {
        print("Outer error")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }

  @Test("Do statement with tuple assignment generates correct syntax")
  internal func testDoStatementWithTupleAssignment() throws {
    let doStatement = Do {
      TupleAssignment(
        ["x", "y"],
        equals: Tuple {
          Literal.integer(10)
          Literal.integer(20)
        }
      )
      Call("processCoordinates") {
        ParameterExp(name: "x", value: VariableExp("x"))
        ParameterExp(name: "y", value: VariableExp("y"))
      }
    } catch: {
      Catch {
        Call("print") {
          ParameterExp(unlabeled: Literal.string("Error processing coordinates"))
        }
      }
    }

    let generated = doStatement.generateCode()
    let expected = """
      do {
        let (x, y) = (10, 20)
        processCoordinates(x: x, y: y)
      } catch {
        print("Error processing coordinates")
      }
      """

    #expect(generated.normalize() == expected.normalize())
  }
}
