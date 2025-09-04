import Foundation

// MARK: - FileManager Extensions


extension FileManager {
  /// Finds documentation files in multiple relative paths
  func findDocumentationFiles(in relativePaths: [String], relativeTo root: URL, pathExtensions: [String]) throws -> [String] {
    try relativePaths.flatMap{
      try findDocumentationFiles(in: $0, relativeTo: root, pathExtensions: pathExtensions)
    }
  }

  /// Finds documentation files in a single directory or file
  func findDocumentationFiles(in relativePath: String, relativeTo root: URL, pathExtensions: [String]) throws -> [String] {
    let fullPath = root.appendingPathComponent(relativePath)
    var documentationFiles: [String] = []

    if fileExists(atPath: fullPath.path) {
      if pathExtensions.contains(where: { relativePath.hasSuffix("." + $0) }) {
        // Single file with matching extension
        documentationFiles.append(relativePath)
      } else {
        // Directory - recursively find files with specified extensions
        let foundFileURLs = try findMarkdownFiles(in: fullPath, pathExtensions: pathExtensions)
        let relativePaths = foundFileURLs.map { fileURL in
          String(fileURL.path.dropFirst(root.path.count + 1))
        }
        documentationFiles.append(contentsOf: relativePaths)
      }
    }

    return documentationFiles
  }

  /// Recursively finds files with specified extensions in a directory
  func findMarkdownFiles(in directory: URL, pathExtensions: [String]) throws -> [URL] {
    let enumerator = self.enumerator(at: directory, includingPropertiesForKeys: nil)

    var markdownFiles: [URL] = []

    while let fileURL = enumerator?.nextObject() as? URL {
      if pathExtensions.contains(fileURL.pathExtension) {
        markdownFiles.append(fileURL)
      }
    }

    return markdownFiles
  }
}
