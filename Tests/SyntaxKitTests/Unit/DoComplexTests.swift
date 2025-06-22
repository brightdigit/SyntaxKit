import Testing

@testable import SyntaxKit

@Suite internal struct DoComplexTests {
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
}
