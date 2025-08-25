//
//  EnumSetTests.swift
//  SimulatorServices
//
//  Created by Leo Dion.
//  Copyright © 2024 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

@testable import Options
import Testing

@Suite
internal struct EnumSetTests {
  private static let text = "[\"a\",\"b\",\"c\"]"

  @Test
  internal func decoder() {
    // swiftlint:disable:next force_unwrapping
    let data = Self.text.data(using: .utf8)!
    let decoder = JSONDecoder()
    let actual: EnumSet<MockCollectionEnum>
    do {
      actual = try decoder.decode(EnumSet<MockCollectionEnum>.self, from: data)
    } catch {
      Issue.record("Unexpected error: \(error)")
      return
    }
    #expect(actual.rawValue == 7)
  }

  @Test
  internal func encoder() {
    let enumSet = EnumSet<MockCollectionEnum>(values: [.a, .b, .c])
    let encoder = JSONEncoder()
    let data: Data
    do {
      data = try encoder.encode(enumSet)
    } catch {
      Issue.record("Unexpected error: \(error)")
      return
    }

    let dataText = String(bytes: data, encoding: .utf8)

    guard let text = dataText else {
      Issue.record("Failed to convert data to string")
      return
    }

    #expect(text == Self.text)
  }

  @Test
  internal func initValue() {
    let set = EnumSet<MockCollectionEnum>(rawValue: 7)
    #expect(set.rawValue == 7)
  }

  @Test
  internal func initValues() {
    let values: [MockCollectionEnum] = [.a, .b, .c]
    let setA = EnumSet(values: values)
    #expect(setA.rawValue == 7)
    let setB: MockCollectionEnumSet = [.a, .b, .c]
    #expect(setB.rawValue == 7)
  }

  @Test
  internal func array() {
    let expected: [MockCollectionEnum] = [.b, .d]
    let enumSet = EnumSet<MockCollectionEnum>(values: expected)
    let actual = enumSet.array()
    #expect(actual == expected)
  }
}
