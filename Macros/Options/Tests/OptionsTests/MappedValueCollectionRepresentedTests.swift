//
//  MappedValueCollectionRepresentedTests.swift
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
internal struct MappedValueCollectionRepresentedTests {
  @Test
  internal func rawValue() throws {
    #expect(try MockCollectionEnum.rawValue(basedOn: "a") == 0)
    #expect(try MockCollectionEnum.rawValue(basedOn: "b") == 1)
    #expect(try MockCollectionEnum.rawValue(basedOn: "c") == 2)
    #expect(try MockCollectionEnum.rawValue(basedOn: "d") == 3)
  }

  @Test
  internal func string() throws {
    #expect(try MockCollectionEnum.mappedValue(basedOn: 0) == "a")
    #expect(try MockCollectionEnum.mappedValue(basedOn: 1) == "b")
    #expect(try MockCollectionEnum.mappedValue(basedOn: 2) == "c")
    #expect(try MockCollectionEnum.mappedValue(basedOn: 3) == "d")
  }

  @Test
  internal func rawValueFailure() {
    let caughtError: MappedValueRepresentableError?
    do {
      _ = try MockCollectionEnum.rawValue(basedOn: "e")
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
      _ = try MockCollectionEnum.mappedValue(basedOn: .max)
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
  internal func codingOptions() {
    #expect(MockDictionaryEnum.codingOptions == .default)
  }

  @Test
  internal func invalidRaw() throws {
    let rawValue = Int.random(in: 5 ... 1_000)

    let rawValueJSON = "\(rawValue)"

    let rawValueJSONData = rawValueJSON.data(using: .utf8)!

    let decodingError: DecodingError
    do {
      let value = try Self.decoder.decode(MockCollectionEnum.self, from: rawValueJSONData)
      Issue.record("Expected decoding to fail but got value: \(value)")
      return
    } catch let error as DecodingError {
      decodingError = error
    }

    // Expect that we caught a decoding error (test passes if we reach here)
    _ = decodingError
  }

  @Test
  internal func codable() throws {
    let argumentSets = MockCollectionEnum.allCases.flatMap {
      [($0, true), ($0, false)]
    }.flatMap {
      [($0.0, $0.1, true), ($0.0, $0.1, false)]
    }

    for arguments in argumentSets {
      try codableTest(value: arguments.0, allowMappedValue: arguments.1, encodeAsMappedValue: arguments.2)
    }
  }

  static let encoder = JSONEncoder()
  static let decoder = JSONDecoder()

  private func codableTest(value: MockCollectionEnum, allowMappedValue: Bool, encodeAsMappedValue: Bool) throws {
    let mappedValue = try value.mappedValue()
    let rawValue = value.rawValue

    let mappedValueJSON = "\"\(mappedValue)\""
    let rawValueJSON = "\(rawValue)"

    let mappedValueJSONData = mappedValueJSON.data(using: .utf8)!
    let rawValueJSONData = rawValueJSON.data(using: .utf8)!

    let oldOptions = MockCollectionEnum.codingOptions
    MockCollectionEnum.codingOptions = .init([
      allowMappedValue ? CodingOptions.allowMappedValueDecoding : nil,
      encodeAsMappedValue ? CodingOptions.encodeAsMappedValue : nil
    ].compactMap { $0 })

    defer {
      MockCollectionEnum.codingOptions = oldOptions
    }

    let mappedDecodeResult = Result {
      try Self.decoder.decode(MockCollectionEnum.self, from: mappedValueJSONData)
    }

    let actualRawValueDecoded = try Self.decoder.decode(MockCollectionEnum.self, from: rawValueJSONData)

    let actualEncodedJSON = try Self.encoder.encode(value)

    switch (allowMappedValue, mappedDecodeResult) {
    case (true, let .success(actualMappedDecodedValue)):
      #expect(actualMappedDecodedValue == value)
    case (false, let .failure(error)):
      #expect(error is DecodingError)
    default:
      Issue.record("Unmatched situation \(allowMappedValue): \(mappedDecodeResult)")
    }

    #expect(actualRawValueDecoded == value)

    #expect(actualEncodedJSON == (encodeAsMappedValue ? mappedValueJSONData : rawValueJSONData))
  }
}
