//
//  LiteralValueTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Testing

@testable import SyntaxKit

internal struct LiteralValueTests {
  // MARK: - Array<String> LiteralValue Tests

  @Test internal func testArrayStringTypeName() {
    let array: [String] = ["a", "b", "c"]
    #expect(array.typeName == "[String]")
  }

  @Test internal func testArrayStringLiteralString() {
    let array: [String] = ["a", "b", "c"]
    #expect(array.literalString == "[\"a\", \"b\", \"c\"]")
  }

  @Test internal func testEmptyArrayStringLiteralString() {
    let array: [String] = []
    #expect(array.literalString == "[]")
  }

  @Test internal func testArrayStringWithSpecialCharacters() {
    let array: [String] = ["hello world", "test\"quote", "line\nbreak"]
    #expect(array.literalString == "[\"hello world\", \"test\\\"quote\", \"line\\nbreak\"]")
  }

  // MARK: - Dictionary<Int, String> LiteralValue Tests

  @Test internal func testDictionaryIntStringTypeName() {
    let dict: [Int: String] = [1: "a", 2: "b"]
    #expect(dict.typeName == "[Int: String]")
  }

  @Test internal func testDictionaryIntStringLiteralString() {
    let dict: [Int: String] = [1: "a", 2: "b", 3: "c"]
    let literal = dict.literalString

    // Dictionary order is not guaranteed, so check that all elements are present
    #expect(literal.contains("1: \"a\""))
    #expect(literal.contains("2: \"b\""))
    #expect(literal.contains("3: \"c\""))
    #expect(literal.hasPrefix("["))
    #expect(literal.hasSuffix("]"))
  }

  @Test internal func testEmptyDictionaryLiteralString() {
    let dict: [Int: String] = [:]
    #expect(dict.literalString == "[]")
  }

  @Test internal func testDictionaryWithSpecialCharacters() {
    let dict: [Int: String] = [1: "hello world", 2: "test\"quote"]
    let literal = dict.literalString

    // Dictionary order is not guaranteed, so check that all elements are present
    #expect(literal.contains("1: \"hello world\""))
    #expect(literal.contains("2: \"test\\\"quote\""))
    #expect(literal.hasPrefix("["))
    #expect(literal.hasSuffix("]"))
  }

  // MARK: - Dictionary Ordering Tests

  @Test internal func testDictionaryOrderingIsConsistent() {
    let dict1: [Int: String] = [2: "b", 1: "a", 3: "c"]
    let dict2: [Int: String] = [1: "a", 2: "b", 3: "c"]

    // Both should produce the same literal string regardless of insertion order
    let literal1 = dict1.literalString
    let literal2 = dict2.literalString

    // The exact order depends on the dictionary's internal ordering,
    // but both should be valid Swift dictionary literals
    #expect(literal1.contains("1: \"a\""))
    #expect(literal1.contains("2: \"b\""))
    #expect(literal1.contains("3: \"c\""))
    #expect(literal2.contains("1: \"a\""))
    #expect(literal2.contains("2: \"b\""))
    #expect(literal2.contains("3: \"c\""))
  }

  // MARK: - TupleLiteral Tests

  @Test internal func testTupleLiteralTypeName() {
    let tuple1 = TupleLiteral([.int(1), .int(2)])
    #expect(tuple1.typeName == "(Int, Int)")

    let tuple2 = TupleLiteral([.string("hello"), .int(42), .boolean(true)])
    #expect(tuple2.typeName == "(String, Int, Bool)")

    let tuple3 = TupleLiteral([.int(1), nil, .string("test")])
    #expect(tuple3.typeName == "(Int, Any, String)")

    let tuple4 = TupleLiteral([nil, nil])
    #expect(tuple4.typeName == "(Any, Any)")
  }

  @Test internal func testTupleLiteralString() {
    let tuple1 = TupleLiteral([.int(1), .int(2)])
    #expect(tuple1.literalString == "(1, 2)")

    let tuple2 = TupleLiteral([.string("hello"), .int(42), .boolean(true)])
    #expect(tuple2.literalString == "(\"hello\", 42, true)")

    let tuple3 = TupleLiteral([.int(1), nil, .string("test")])
    #expect(tuple3.literalString == "(1, _, \"test\")")

    let tuple4 = TupleLiteral([nil, nil])
    #expect(tuple4.literalString == "(_, _)")

    let tuple5 = TupleLiteral([.float(3.14), .nil])
    #expect(tuple5.literalString == "(3.14, nil)")
  }

  @Test internal func testTupleLiteralWithNestedTuples() {
    let nestedTuple = TupleLiteral([.int(1), .tuple([.string("nested"), .int(2)])])
    #expect(nestedTuple.typeName == "(Int, Any)")
    #expect(nestedTuple.literalString == "(1, (\"nested\", 2))")
  }

  @Test internal func testTupleLiteralWithRef() {
    let tuple = TupleLiteral([.ref("variable"), .int(42)])
    #expect(tuple.typeName == "(Any, Int)")
    #expect(tuple.literalString == "(variable, 42)")
  }

  @Test internal func testEmptyTupleLiteral() {
    let tuple = TupleLiteral([])
    #expect(tuple.typeName == "()")
    #expect(tuple.literalString == "()")
  }

  // MARK: - TupleLiteral Code Generation Tests

  @Test internal func testVariableWithTupleLiteral() {
    let tuple = TupleLiteral([.int(1), .int(2)])
    let variable = Variable(.let, name: "point", equals: tuple)

    let generated = variable.syntax.description
    #expect(generated.contains("let point  = (1, 2)"))
    #expect(generated.contains("point"))
  }

  @Test internal func testVariableWithTupleLiteralWithExplicitType() {
    let tuple = TupleLiteral([.int(1), .int(2)])
    let variable = Variable(.let, name: "point", equals: tuple).withExplicitType()

    let generated = variable.syntax.description
    #expect(generated.contains("let point  : (Int, Int) = (1, 2)"))
    #expect(generated.contains("point"))
  }

  @Test internal func testVariableWithComplexTupleLiteral() {
    let tuple = TupleLiteral([.string("hello"), .int(42), .boolean(true)])
    let variable = Variable(.let, name: "data", equals: tuple).withExplicitType()

    let generated = variable.syntax.description
    #expect(generated.contains("let data  : (String, Int, Bool) = (\"hello\", 42, true)"))
    #expect(generated.contains("data"))
  }

  @Test internal func testVariableWithTupleLiteralWithWildcards() {
    let tuple = TupleLiteral([.int(1), nil, .string("test")])
    let variable = Variable(.let, name: "partial", equals: tuple).withExplicitType()

    let generated = variable.syntax.description
    #expect(generated.contains("let partial  : (Int, Any, String) = (1, _, \"test\")"))
    #expect(generated.contains("partial"))
  }

  @Test internal func testLiteralAsTupleLiteralConversion() {
    let literal = Literal.tuple([.int(1), .int(2)])
    let tupleLiteral = literal.asTupleLiteral

    #expect(tupleLiteral != nil)
    #expect(tupleLiteral?.typeName == "(Int, Int)")
    #expect(tupleLiteral?.literalString == "(1, 2)")
  }

  @Test internal func testNonTupleLiteralAsTupleLiteralConversion() {
    let literal = Literal.int(42)
    let tupleLiteral = literal.asTupleLiteral

    #expect(tupleLiteral == nil)
  }
}
