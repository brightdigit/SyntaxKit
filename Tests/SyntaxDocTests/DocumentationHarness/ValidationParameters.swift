//
//  ValidationParameters.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//
import Foundation

/// Protocol defining the parameters required for Swift code validation
internal protocol ValidationParameters {
  /// The Swift code to validate
  var code: String { get }

  /// The file URL where the code was found
  var fileURL: URL { get }

  /// The line number where the code was found
  var lineNumber: Int { get }
}
