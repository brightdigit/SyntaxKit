//
//  MappedValueDictionaryRepresentedTests.swift
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

internal final class MappedValueDictionaryRepresentedTests: XCTestCase {
  internal func testRawValue() {
    try XCTAssertEqual(MockDictionaryEnum.rawValue(basedOn: "a"), 2)
    try XCTAssertEqual(MockDictionaryEnum.rawValue(basedOn: "b"), 5)
    try XCTAssertEqual(MockDictionaryEnum.rawValue(basedOn: "c"), 6)
    try XCTAssertEqual(MockDictionaryEnum.rawValue(basedOn: "d"), 12)
  }

  internal func testString() {
    try XCTAssertEqual(MockDictionaryEnum.mappedValue(basedOn: 2), "a")
    try XCTAssertEqual(MockDictionaryEnum.mappedValue(basedOn: 5), "b")
    try XCTAssertEqual(MockDictionaryEnum.mappedValue(basedOn: 6), "c")
    try XCTAssertEqual(MockDictionaryEnum.mappedValue(basedOn: 12), "d")
  }

  internal func testRawValueFailure() {
    let caughtError: MappedValueRepresentableError?
    do {
      _ = try MockDictionaryEnum.rawValue(basedOn: "e")
      caughtError = nil
    } catch let error as MappedValueRepresentableError {
      caughtError = error
    } catch {
      XCTAssertNil(error)
      caughtError = nil
    }

    XCTAssertEqual(caughtError, .valueNotFound)
  }

  internal func testStringFailure() {
    let caughtError: MappedValueRepresentableError?
    do {
      _ = try MockDictionaryEnum.mappedValue(basedOn: 0)
      caughtError = nil
    } catch let error as MappedValueRepresentableError {
      caughtError = error
    } catch {
      XCTAssertNil(error)
      caughtError = nil
    }

    XCTAssertEqual(caughtError, .valueNotFound)
  }
}
