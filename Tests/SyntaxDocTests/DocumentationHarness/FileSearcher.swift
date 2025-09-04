//
//  FileSearcher.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/4/25.
//

import Foundation

protocol FileSearcher {
  func searchDirectory(at path: URL, forExtensions pathExtensions: [String]) throws(FileSearchError)
    -> [URL]
}

extension FileSearcher {
  func findDocumentationFiles(in path: URL, pathExtensions: [String]) throws(FileSearchError)
    -> [URL]
  {
    let resourceValues: URLResourceValues
    do {
      resourceValues = try path.resourceValues(forKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotAccessPath(path.path, underlying: error)
    }

    if resourceValues.isDirectory == true {
      return try searchDirectory(at: path, forExtensions: pathExtensions)
    } else {
      // Single file - check if it has a matching extension
      if pathExtensions.contains(where: { path.path.hasSuffix("." + $0) }) {
        return [path]
      } else {
        return []
      }
    }
  }
}
