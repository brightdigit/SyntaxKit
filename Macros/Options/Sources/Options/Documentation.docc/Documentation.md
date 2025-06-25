# ``Options``

More powerful options for `Enum` and `OptionSet` types.

## Overview

**Options** provides a powerful set of features for `Enum` and `OptionSet` types:

- Providing additional representations for `Enum` types besides the `RawType rawValue` 
- Being able to interchange between `Enum` and `OptionSet` types
- Using an additional value type for a `Codable` `OptionSet`

### Requirements 

**Apple Platforms**

- Xcode 14.1 or later
- Swift 5.7.1 or later
- iOS 16 / watchOS 9 / tvOS 16 / macOS 12 or later deployment targets

**Linux**

- Ubuntu 20.04 or later
- Swift 5.7.1 or later

### Installation

Use the Swift Package Manager to install this library via the repository url:

```
https://github.com/brightdigit/Options.git
```

Use version up to `1.0`.

### Versatile Options

Let's say we are using an `Enum` for a list of popular social media networks:

```swift
enum SocialNetwork : Int {
  case digg
  case aim
  case bebo
  case delicious
  case eworld
  case googleplus
  case itunesping
  case jaiku
  case miiverse
  case musically
  case orkut
  case posterous
  case stumbleupon
  case windowslive
  case yahoo
}
```

We'll be using this as a way to define a particular social handle:

```swift
struct SocialHandle {
  let name : String
  let network : SocialNetwork
}
```

However we also want to provide a way to have a unique set of social networks available:

```swift
struct SocialNetworkSet : Int, OptionSet {
...
}

let user : User
let networks : SocialNetworkSet = user.availableNetworks()
```

We can then simply use ``Options()`` macro to generate both these types:

```swift
@Options
enum SocialNetwork : Int {
  case digg
  case aim
  case bebo
  case delicious
  case eworld
  case googleplus
  case itunesping
  case jaiku
  case miiverse
  case musically
  case orkut
  case posterous
  case stumbleupon
  case windowslive
  case yahoo
}
```

Now we can use the newly create `SocialNetworkSet` type to store a set of values:

```swift
let networks : SocialNetworkSet
networks = [.aim, .delicious, .googleplus, .windowslive]
```

### Multiple Value Types

With the ``Options()`` macro, we add the ability to encode and decode values not only from their raw value but also from a another type such as a string. This is useful for when you want to store the values in JSON format.

For instance, with a type like `SocialNetwork` we need need to store the value as an Integer:

```json
5
```

However by adding the ``Options()`` macro we can also decode from a String:

```
"googleplus"
```

### Creating an OptionSet

We can also have a new `OptionSet` type created. ``Options()`` create a new `OptionSet` type with the suffix `-Set`. This new `OptionSet` will automatically work with your enum to create a distinct set of values. Additionally it will decode and encode your values as an Array of String. This means the value:

```swift
[.aim, .delicious, .googleplus, .windowslive]
```

is encoded as:

```json
["aim", "delicious", "googleplus", "windowslive"]
```

## Topics

### Options conformance

- ``Options()``
- ``MappedValueRepresentable``
- ``MappedValueRepresented``
- ``EnumSet``

### Advanced customization

- ``CodingOptions``
- ``MappedValues``

### Errors

- ``MappedValueRepresentableError-2k4ki``

### Deprecated 

- ``MappedValueCollectionRepresented``
- ``MappedValueDictionaryRepresented``
- ``MappedEnum``
