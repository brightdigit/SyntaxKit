import Foundation

// MARK: - Documentation Error Types



// MARK: - FileManager Extensions

extension FileManager: FileSearcher {
  private func searchItem(_ itemURL: URL, _ pathExtensions: [String]) throws(FileSearchError)
    -> [URL]
  {
    var documentationFiles = [URL]()

    let itemResourceValues: URLResourceValues
    do {
      itemResourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotAccessPath(itemURL.path, underlying: error)
    }

    if itemResourceValues.isDirectory == true {
      // Recursively call this method for subdirectories
      let subdirectoryFiles = try findDocumentationFiles(
        in: itemURL, pathExtensions: pathExtensions)
      documentationFiles.append(contentsOf: subdirectoryFiles)
    } else if pathExtensions.contains(where: { itemURL.path.hasSuffix("." + $0) }) {
      // Direct file with matching extension
      documentationFiles.append(itemURL)
    }
    return documentationFiles
  }

  internal func searchDirectory(at path: URL, forExtensions pathExtensions: [String])
    throws(FileSearchError) -> [URL]
  {
    let contents: [URL]
    do {
      contents = try contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey])
    } catch {
      throw FileSearchError.cannotReadDirectory(path.path, underlying: error)
    }

    // Directory - recursively find files with specified extensions
    let documentationFiles: [URL]
    do {
      documentationFiles = try contents.flatMap({ itemURL in
        try searchItem(itemURL, pathExtensions)
      })
    } catch let fileSearchError as FileSearchError {
      throw fileSearchError
    } catch {
      assertionFailure("Should only be a FileSearchError: \(error.localizedDescription)")
      throw .unknownError(error)
    }

    return documentationFiles
  }
}
