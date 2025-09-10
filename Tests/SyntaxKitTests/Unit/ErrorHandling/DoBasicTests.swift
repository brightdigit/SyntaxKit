import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct DoBasicTests {
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
}
