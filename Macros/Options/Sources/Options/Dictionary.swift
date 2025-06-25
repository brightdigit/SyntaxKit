//
//  Dictionary.swift
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

// swiftlint:disable:next line_length
@available(*, deprecated, renamed: "MappedValueGenericRepresented", message: "Use MappedValueGenericRepresented instead.")
public protocol MappedValueDictionaryRepresented: MappedValueRepresented
  where MappedValueType == [Int: MappedType] {}

extension Dictionary: MappedValues where Value: Equatable {
  public func key(value: Value) throws -> Key {
    let pair = first { $0.value == value }
    guard let key = pair?.key else {
      throw MappedValueRepresentableError.valueNotFound
    }

    return key
  }

  public func value(key: Key) throws -> Value {
    guard let value = self[key] else {
      throw MappedValueRepresentableError.valueNotFound
    }
    return value
  }
}
