//
//  FileSearchError.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/4/25.
//

import Foundation

enum FileSearchError: Error, LocalizedError {
  case cannotAccessPath(String, underlying: any Error)
  case cannotReadDirectory(String, underlying: any Error)
  case unknownError(any Error)

  var errorDescription: String? {
    switch self {
    case .cannotAccessPath(let path, let underlying):
      return "Cannot access path '\(path)': \(underlying.localizedDescription)"
    case .cannotReadDirectory(let path, let underlying):
      return "Cannot read directory '\(path)': \(underlying.localizedDescription)"
    case .unknownError(let error):
      return "Unknown Error: \(error)"
    }
  }
}