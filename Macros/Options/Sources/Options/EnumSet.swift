/// Generic struct for using Enums with `RawValue`.
///
/// If you have an `enum` such as:
/// ```swift
/// @Options
/// enum SocialNetwork : Int {
///   case digg
///   case aim
///   case bebo
///   case delicious
///   case eworld
///   case googleplus
///   case itunesping
///   case jaiku
///   case miiverse
///   case musically
///   case orkut
///   case posterous
///   case stumbleupon
///   case windowslive
///   case yahoo
/// }
/// ```
///  An ``EnumSet`` could be used to store multiple values as an `OptionSet`:
/// ```swift
/// let socialNetworks : EnumSet<SocialNetwork> =
///   [.digg, .aim, .yahoo, .miiverse]
/// ```
public struct EnumSet<EnumType: RawRepresentable>:
  OptionSet, Sendable, ExpressibleByArrayLiteral
  where EnumType.RawValue: FixedWidthInteger & Sendable {
  public typealias RawValue = EnumType.RawValue

  /// Raw Value of the OptionSet
  public let rawValue: RawValue

  /// Creates the EnumSet based on the `rawValue`
  /// - Parameter rawValue: Integer raw value of the OptionSet
  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }

  public init(arrayLiteral elements: EnumType...) {
    self.init(values: elements)
  }

  /// Creates the EnumSet based on the values in the array.
  /// - Parameter values: Array of enum values.
  public init(values: [EnumType]) {
    let set = Set(values.map(\.rawValue))
    rawValue = Self.cumulativeValue(basedOnRawValues: set)
  }

  internal static func cumulativeValue(
    basedOnRawValues rawValues: Set<RawValue>) -> RawValue {
    rawValues.map { 1 << $0 }.reduce(0, |)
  }
}

extension FixedWidthInteger {
  fileprivate static var one: Self {
    1
  }
}

extension EnumSet where EnumType: CaseIterable {
  internal static func enums(basedOnRawValue rawValue: RawValue) -> [EnumType] {
    let cases = EnumType.allCases.sorted { $0.rawValue < $1.rawValue }
    var values = [EnumType]()
    var current = rawValue
    for item in cases {
      guard current > 0 else {
        break
      }
      let rawValue = RawValue.one << item.rawValue
      if current & rawValue != .zero {
        values.append(item)
        current -= rawValue
      }
    }
    return values
  }

  /// Returns an array of the enum values based on the OptionSet
  /// - Returns: Array for each value represented by the enum.
  public func array() -> [EnumType] {
    Self.enums(basedOnRawValue: rawValue)
  }
}

#if swift(>=5.9)
  extension EnumSet: Codable
    where EnumType: MappedValueRepresentable, EnumType.MappedType: Codable {
    /// Decodes the EnumSet based on an Array of MappedTypes.
    /// - Parameter decoder: Decoder which contains info as an array of MappedTypes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let values = try container.decode([EnumType.MappedType].self)
      let rawValues = try values.map(EnumType.rawValue(basedOn:))
      let set = Set(rawValues)
      rawValue = Self.cumulativeValue(basedOnRawValues: set)
    }

    /// Encodes the EnumSet based on an Array of MappedTypes.
    /// - Parameter encoder: Encoder which will contain info as an array of MappedTypes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      let values = Self.enums(basedOnRawValue: rawValue)
      let mappedValues = try values
        .map(\.rawValue)
        .map(EnumType.mappedValue(basedOn:))
      try container.encode(mappedValues)
    }
  }
#else
  extension EnumSet: Codable
    where EnumType: MappedValueRepresentable, EnumType.MappedType: Codable {
    /// Decodes the EnumSet based on an Array of MappedTypes.
    /// - Parameter decoder: Decoder which contains info as an array of MappedTypes.
    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let values = try container.decode([EnumType.MappedType].self)
      let rawValues = try values.map(EnumType.rawValue(basedOn:))
      let set = Set(rawValues)
      rawValue = Self.cumulativeValue(basedOnRawValues: set)
    }

    /// Encodes the EnumSet based on an Array of MappedTypes.
    /// - Parameter encoder: Encoder which will contain info as an array of MappedTypes.
    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      let values = Self.enums(basedOnRawValue: rawValue)
      let mappedValues = try values
        .map(\.rawValue)
        .map(EnumType.mappedValue(basedOn:))
      try container.encode(mappedValues)
    }
  }
#endif
