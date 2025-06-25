//
//  MappedValueRepresented.swift
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

/// Protocol which simplifies ``MappedValueRepresentable``by using a ``MappedValues``.
public protocol MappedValueRepresented: MappedValueRepresentable
  where MappedType: Equatable {
  /// A object to lookup values and keys for mapped values.
  associatedtype MappedValueType: MappedValues<RawValue, MappedType>
  /// An array of the mapped values which lines up with each case.
  static var mappedValues: MappedValueType { get }
}

extension MappedValueRepresented {
  /// Gets the raw value based on the MappedType by finding the index of the mapped value.
  /// - Parameter value: MappedType value.
  /// - Throws: `MappedValueCollectionRepresentedError.valueNotFound`
  ///   If the value was not found in the array
  /// - Returns:
  ///   The raw value of the enumeration
  ///   based on the index the MappedType value was found at.
  public static func rawValue(basedOn value: MappedType) throws -> RawValue {
    try mappedValues.key(value: value)
  }

  /// Gets the mapped value based on the rawValue
  /// by access the array at the raw value subscript.
  /// - Parameter rawValue: The raw value of the enumeration
  ///   which pretains to its index in the `mappedValues` Array.
  /// - Throws: `MappedValueCollectionRepresentedError.valueNotFound`
  ///   if the raw value (i.e. index) is outside the range of the `mappedValues` array.
  /// - Returns:
  ///   The Mapped Type value based on the value in the array at the raw value index.
  public static func mappedValue(basedOn rawValue: RawValue) throws -> MappedType {
    try mappedValues.value(key: rawValue)
  }
}
