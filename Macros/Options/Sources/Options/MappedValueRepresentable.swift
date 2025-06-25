//
//  MappedValueRepresentable.swift
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

/// An enum which has an additional value attached.
/// - Note: ``Options()`` macro will automatically set this up for you.
public protocol MappedValueRepresentable: RawRepresentable, CaseIterable, Sendable {
  /// The additional value type.
  associatedtype MappedType = String

  /// Options for how the enum should be decoded or encoded.
  static var codingOptions: CodingOptions {
    get
  }

  /// Gets the raw value based on the MappedType.
  /// - Parameter value: MappedType value.
  /// - Returns: The raw value of the enumeration based on the `MappedType `value.
  static func rawValue(basedOn string: MappedType) throws -> RawValue

  /// Gets the `MappedType` value based on the `rawValue`.
  /// - Parameter rawValue: The raw value of the enumeration.
  /// - Returns: The Mapped Type value based on the `rawValue`.
  static func mappedValue(basedOn rawValue: RawValue) throws -> MappedType
}

extension MappedValueRepresentable {
  /// Options regarding how the type can be decoded or encoded.
  public static var codingOptions: CodingOptions {
    .default
  }

  /// Gets the mapped value of the enumeration.
  /// - Parameter rawValue: The raw value of the enumeration
  ///   which pretains to its index in the `mappedValues` Array.
  /// - Throws: `MappedValueCollectionRepresentedError.valueNotFound`
  ///   if the raw value (i.e. index) is outside the range of the `mappedValues` array.
  /// - Returns:
  ///   The Mapped Type value based on the value in the array at the raw value index.
  public func mappedValue() throws -> MappedType {
    try Self.mappedValue(basedOn: rawValue)
  }
}
