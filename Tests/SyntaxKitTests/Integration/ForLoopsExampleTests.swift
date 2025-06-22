import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ForLoopsExampleTests {
  @Test("Completed for loops DSL generates expected Swift code")
  internal func testCompletedForLoopsExample() throws {
    // Build DSL equivalent of Examples/Completed/for_loops/dsl.swift

    let program = Group {
      // MARK: - Basic For-in Loop
      Variable(
        .let,
        name: "names",
        equals: Literal.array([
          Literal.string("Alice"),
          Literal.string("Bob"),
          Literal.string("Charlie"),
        ])
      )
      .comment {
        Line("MARK: - Basic For-in Loop")
        Line("Simple for-in loop over an array")
      }

      For(
        VariableExp("name"),
        in: VariableExp("names"),
        then: {
          Call("print") {
            ParameterExp(unlabeled: "\"Hello, \\(name)!\"")
          }
        }
      )

      // MARK: - For-in with Enumerated
      Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Enumerated ===\"")
      }
      .comment {
        Line("MARK: - For-in with Enumerated")
        Line("For-in loop with enumerated() to get index and value")
      }
      For(
        Tuple.patternCodeBlock([
          VariableExp("index"),
          VariableExp("name"),
        ]),
        in: VariableExp("names").call("enumerated"),
        then: {
          Call("print") {
            ParameterExp(unlabeled: "\"Index: \\(index), Name: \\(name)\"")
          }
        }
      )

      // MARK: - For-in with Where Clause
      Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Where Clause ===\"")
      }
      .comment {
        Line("MARK: - For-in with Where Clause")
        Line("For-in loop with where clause")
      }
      Variable(
        .let,
        name: "numbers",
        equals: Literal.array([
          Literal.integer(1),
          Literal.integer(2),
          Literal.integer(3),
          Literal.integer(4),
          Literal.integer(5),
          Literal.integer(6),
          Literal.integer(7),
          Literal.integer(8),
          Literal.integer(9),
          Literal.integer(10),
        ])
      )

      For(
        VariableExp("number"),
        in: VariableExp("numbers"),
        where: {
          Infix("==") {
            Infix("%") {
              VariableExp("number")
              Literal.integer(2)
            }
            Literal.integer(0)
          }
        },
        then: {
          Call("print") {
            ParameterExp(unlabeled: "\"Even number: \\(number)\"")
          }
        }
      )

      // MARK: - For-in with Dictionary
      Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Dictionary ===\"")
      }
      .comment {
        Line("MARK: - For-in with Dictionary")
        Line("For-in loop over dictionary")
      }
      Variable(
        .let,
        name: "scores",
        equals: Literal.dictionary([
          (Literal.string("Alice"), Literal.integer(95)),
          (Literal.string("Bob"), Literal.integer(87)),
          (Literal.string("Charlie"), Literal.integer(92)),
        ])
      )

      For(
        Tuple.patternCodeBlock([
          VariableExp("name"),
          VariableExp("score"),
        ]),
        in: VariableExp("scores"),
        then: {
          Call("print") {
            ParameterExp(unlabeled: "\"\\(name): \\(score)\"")
          }
        }
      )
    }

    // Generate Swift from DSL
    var generated = program.generateCode()

    // Remove type annotations like ": Int =" for comparison to example code
    generated = generated.normalize()

    // Use the expected Swift code as a string literal
    let expected = """
      // MARK: - Basic For-in Loop
      // Simple for-in loop over an array
      let names = ["Alice", "Bob", "Charlie"]
      for name in names {
        print("Hello, \\(name)!")
      }

      // MARK: - For-in with Enumerated
      // For-in loop with enumerated() to get index and value
      print("\\n=== For-in with Enumerated ===")
      for (index, name) in names.enumerated() {
        print("Index: \\(index), Name: \\(name)")
      }

      // MARK: - For-in with Where Clause
      // For-in loop with where clause
      print("\\n=== For-in with Where Clause ===")
      let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      for number in numbers where number % 2 == 0 {
        print("Even number: \\(number)")
      }

      // MARK: - For-in with Dictionary
      // For-in loop over dictionary
      print("\\n=== For-in with Dictionary ===")
      let scores = ["Alice": 95, "Bob": 87, "Charlie": 92]
      for (name, score) in scores {
        print("\\(name): \\(score)")
      }
      """
      .normalize()

    #expect(generated == expected)
  }
}
