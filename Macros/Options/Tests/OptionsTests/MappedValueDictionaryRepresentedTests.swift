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
import Testing

@Suite
internal struct MappedValueDictionaryRepresentedTests {
  @Test
  internal func rawValue() throws {
    #expect(try MockDictionaryEnum.rawValue(basedOn: "a") == 2)
    #expect(try MockDictionaryEnum.rawValue(basedOn: "b") == 5)
    #expect(try MockDictionaryEnum.rawValue(basedOn: "c") == 6)
    #expect(try MockDictionaryEnum.rawValue(basedOn: "d") == 12)
  }

  @Test
  internal func string() throws {
    #expect(try MockDictionaryEnum.mappedValue(basedOn: 2) == "a")
    #expect(try MockDictionaryEnum.mappedValue(basedOn: 5) == "b")
    #expect(try MockDictionaryEnum.mappedValue(basedOn: 6) == "c")
    #expect(try MockDictionaryEnum.mappedValue(basedOn: 12) == "d")
  }

  @Test
  internal func rawValueFailure() {
    let caughtError: MappedValueRepresentableError?
    do {
      _ = try MockDictionaryEnum.rawValue(basedOn: "e")
      caughtError = nil
    } catch let error as MappedValueRepresentableError {
      caughtError = error
    } catch {
      Issue.record("Unexpected error: \(error)")
      caughtError = nil
    }

    #expect(caughtError == .valueNotFound)
  }

  @Test
  internal func stringFailure() {
    let caughtError: MappedValueRepresentableError?
    do {
      _ = try MockDictionaryEnum.mappedValue(basedOn: 0)
      caughtError = nil
    } catch let error as MappedValueRepresentableError {
      caughtError = error
    } catch {
      Issue.record("Unexpected error: \(error)")
      caughtError = nil
    }

    #expect(caughtError == .valueNotFound)
  }
}
