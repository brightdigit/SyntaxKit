//
//  Array.swift
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
public protocol MappedValueCollectionRepresented: MappedValueRepresented
  where MappedValueType: Sequence {}

extension Array: MappedValues where Element: Equatable {}

extension Collection where Element: Equatable, Self: MappedValues {
  /// Get the index based on the value passed.
  /// - Parameter value: Value to search.
  /// - Returns: Index found.
  public func key(value: Element) throws -> Self.Index {
    guard let index = firstIndex(of: value) else {
      throw MappedValueRepresentableError.valueNotFound
    }

    return index
  }

  /// Gets the value based on the index.
  /// - Parameter key: The index.
  /// - Returns: The value at index.
  public func value(key: Self.Index) throws -> Element {
    guard key < endIndex, key >= startIndex else {
      throw MappedValueRepresentableError.valueNotFound
    }
    return self[key]
  }
}
