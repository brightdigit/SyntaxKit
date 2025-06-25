//
//  MappedValueRepresentable+Codable.swift
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

import Foundation

extension DecodingError {
  internal static func invalidRawValue(_ rawValue: some Any) -> DecodingError {
    .dataCorrupted(
      .init(codingPath: [], debugDescription: "Raw Value \(rawValue) is invalid.")
    )
  }
}

extension SingleValueDecodingContainer {
  fileprivate func decodeAsRawValue<T: MappedValueRepresentable>() throws -> T
    where T.RawValue: Decodable {
    let rawValue = try decode(T.RawValue.self)
    guard let value = T(rawValue: rawValue) else {
      throw DecodingError.invalidRawValue(rawValue)
    }
    return value
  }

  fileprivate func decodeAsMappedType<T: MappedValueRepresentable>() throws -> T
    where T.RawValue: Decodable, T.MappedType: Decodable {
    let mappedValues: T.MappedType
    do {
      mappedValues = try decode(T.MappedType.self)
    } catch {
      return try decodeAsRawValue()
    }

    let rawValue = try T.rawValue(basedOn: mappedValues)

    guard let value = T(rawValue: rawValue) else {
      assertionFailure("Every mappedValue should always return a valid rawValue.")
      throw DecodingError.invalidRawValue(rawValue)
    }

    return value
  }
}

extension MappedValueRepresentable
  where Self: Decodable, MappedType: Decodable, RawValue: Decodable {
  /// Decodes the type.
  /// - Parameter decoder: Decoder.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if Self.codingOptions.contains(.allowMappedValueDecoding) {
      self = try container.decodeAsMappedType()
    } else {
      self = try container.decodeAsRawValue()
    }
  }
}

extension MappedValueRepresentable
  where Self: Encodable, MappedType: Encodable, RawValue: Encodable {
  /// Encoding the type.
  /// - Parameter decoder: Encodes.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    if Self.codingOptions.contains(.encodeAsMappedValue) {
      try container.encode(mappedValue())
    } else {
      try container.encode(rawValue)
    }
  }
}
