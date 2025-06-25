/// A generic struct for enumerations which allow for additional values attached.
@available(
  *,
  deprecated,
  renamed: "MappedValueRepresentable",
  message: "Use `MappedValueRepresentable` with `CodingOptions`."
)
public struct MappedEnum<EnumType: MappedValueRepresentable>: Codable, Sendable
  where EnumType.MappedType: Codable {
  /// Base Enumeraion value.
  public let value: EnumType

  /// Creates an instance based on the base enumeration value.
  /// - Parameter value: Base Enumeration value.
  public init(value: EnumType) {
    self.value = value
  }
}

#if swift(>=5.9)
  extension MappedEnum {
    /// Decodes the value based on the mapped value.
    /// - Parameter decoder: Decoder.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let label = try container.decode(EnumType.MappedType.self)
      let rawValue = try EnumType.rawValue(basedOn: label)
      guard let value = EnumType(rawValue: rawValue) else {
        assertionFailure("Every mappedValue should always return a valid rawValue.")
        throw DecodingError.invalidRawValue(rawValue)
      }
      self.value = value
    }

    /// Encodes the value based on the mapped value.
    /// - Parameter encoder: Encoder.
    public func encode(to encoder: any Encoder) throws {
      let string = try EnumType.mappedValue(basedOn: value.rawValue)
      var container = encoder.singleValueContainer()
      try container.encode(string)
    }
  }
#else
  extension MappedEnum {
    /// Decodes the value based on the mapped value.
    /// - Parameter decoder: Decoder.
    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let label = try container.decode(EnumType.MappedType.self)
      let rawValue = try EnumType.rawValue(basedOn: label)
      guard let value = EnumType(rawValue: rawValue) else {
        assertionFailure("Every mappedValue should always return a valid rawValue.")
        throw DecodingError.invalidRawValue(rawValue)
      }
      self.value = value
    }

    /// Encodes the value based on the mapped value.
    /// - Parameter encoder: Encoder.
    public func encode(to encoder: Encoder) throws {
      let string = try EnumType.mappedValue(basedOn: value.rawValue)
      var container = encoder.singleValueContainer()
      try container.encode(string)
    }
  }
#endif
