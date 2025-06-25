//
//  MappedEnumTests.swift
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
import XCTest

internal final class MappedEnumTests: XCTestCase {
  private static let text = "\"a\""
  internal func testDecoder() throws {
    // swiftlint:disable:next force_unwrapping
    let data = Self.text.data(using: .utf8)!
    let decoder = JSONDecoder()
    let actual: MappedEnum<MockCollectionEnum>
    do {
      actual = try decoder.decode(MappedEnum<MockCollectionEnum>.self, from: data)
    } catch {
      XCTAssertNil(error)
      return
    }
    XCTAssertEqual(actual.value, .a)
  }

  internal func testEncoder() throws {
    let encoder = JSONEncoder()
    let describedEnum: MappedEnum<MockCollectionEnum> = .init(value: .a)
    let data: Data
    do {
      data = try encoder.encode(describedEnum)
    } catch {
      XCTAssertNil(error)
      return
    }

    let dataText = String(bytes: data, encoding: .utf8)

    guard let text = dataText else {
      XCTAssertNotNil(dataText)
      return
    }

    XCTAssertEqual(text, Self.text)
  }
}
