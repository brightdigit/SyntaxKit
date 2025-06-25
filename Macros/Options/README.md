
<p align="center">
    <img alt="Options" title="Options" src="logo.png" height="200">
</p>
<h1 align="center"> Options </h1>

More powerful options for `Enum` and `OptionSet` types.

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Twitter](https://img.shields.io/badge/twitter-@brightdigit-blue.svg?style=flat)](http://twitter.com/brightdigit)
![GitHub](https://img.shields.io/github/license/brightdigit/Options)
![GitHub issues](https://img.shields.io/github/issues/brightdigit/Options)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/Options/Options.yml?label=actions&logo=github&?branch=main)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FOptions%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/Options)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FOptions%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/Options)

[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/Options)](https://codecov.io/gh/brightdigit/Options)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/Options)](https://www.codefactor.io/repository/github/brightdigit/Options)
[![codebeat badge](https://codebeat.co/badges/c47b7e58-867c-410b-80c5-57e10140ba0f)](https://codebeat.co/projects/github-com-brightdigit-mistkit-main)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/brightdigit/Options)](https://codeclimate.com/github/brightdigit/Options)
[![Code Climate technical debt](https://img.shields.io/codeclimate/tech-debt/brightdigit/Options?label=debt)](https://codeclimate.com/github/brightdigit/Options)
[![Code Climate issues](https://img.shields.io/codeclimate/issues/brightdigit/Options)](https://codeclimate.com/github/brightdigit/Options)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)


# Table of Contents

  * [Introduction](#introduction)
  * [Requirements](#requirements)
  * [Installation](#installation)
  * [Usage](#usage)
    * [Versatile Options with Enums and OptionSets](#versatile-options-with-enums-and-optionsets)
    * [Multiple Value Types](#multiple-value-types)
    * [Creating an OptionSet](#creating-an-optionset)
  * [Further Code Documentation](#further-code-documentation)
  * [License](#license)

# Introduction

**Options** provides a powerful set of features for `Enum` and `OptionSet` types:

- Providing additional representations for `Enum` types besides the `RawType rawValue` 
- Being able to interchange between `Enum` and `OptionSet` types
- Using an additional value type for a `Codable` `OptionSet`

# Requirements 

**Apple Platforms**

- Xcode 14.1 or later
- Swift 5.7.1 or later
- iOS 16 / watchOS 9 / tvOS 16 / macOS 12 or later deployment targets

**Linux**

- Ubuntu 20.04 or later
- Swift 5.7.1 or later

# Installation

Use the Swift Package Manager to install this library via the repository url:

```
https://github.com/brightdigit/Options.git
```

Use version up to `1.0`.

# Usage 

## Versatile Options

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

## Multiple Value Types

With the ``Options()`` macro, we add the ability to encode and decode values not only from their raw value but also from a another type such as a string. This is useful for when you want to store the values in JSON format.

For instance, with a type like `SocialNetwork` we need need to store the value as an Integer:

```json
5
```

However by adding the ``Options()`` macro we can also decode from a String:

```
"googleplus"
```

## Creating an OptionSet

We can also have a new `OptionSet` type created. ``Options()`` create a new `OptionSet` type with the suffix `-Set`. This new `OptionSet` will automatically work with your enum to create a distinct set of values. Additionally it will decode and encode your values as an Array of String. This means the value:

```swift
[.aim, .delicious, .googleplus, .windowslive]
```

is encoded as:

```json
["aim", "delicious", "googleplus", "windowslive"]
```

# Further Code Documentation

[Documentation Here](https://swiftpackageindex.com/brightdigit/Options/main/documentation/options)

# License 

This code is distributed under the MIT license. See the [LICENSE](LICENSE) file for more info.
