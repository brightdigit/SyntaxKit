//
//  Helpers.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import CryptoKit
import Foundation

/// Hardcoded module name for the user's `Helpers/` compilation output. Inputs
/// reach the compiled helpers via `import SyntaxKitHelpers`.
internal let helpersModuleName = "SyntaxKitHelpers"

/// Bumped when the cache layout changes in a way that requires invalidation.
private let helpersCacheSchemaVersion = "v1"

/// A compiled `Helpers/` directory ready to splice into the input spawn.
internal struct CompiledHelpers: Sendable {
  /// Directory containing `libSyntaxKitHelpers.dylib` + `.swiftmodule` files.
  let outputDir: URL
  /// Whether the build was reused from cache (false = freshly compiled).
  let cacheHit: Bool
}

// MARK: - Discovery

/// Walks up from `inputURL` looking for a `Helpers/` directory. Returns the
/// first one found, or nil if no ancestor contains one.
///
/// When `inputURL` is a file, the search starts from its parent. When it's a
/// directory, the search starts from the directory itself.
internal func discoverHelpersDir(near inputURL: URL) -> URL? {
  let fm = FileManager.default
  var isDirectory: ObjCBool = false
  let exists = fm.fileExists(atPath: inputURL.path, isDirectory: &isDirectory)
  var dir = (exists && isDirectory.boolValue) ? inputURL : inputURL.deletingLastPathComponent()
  dir = dir.standardizedFileURL

  while true {
    let candidate = dir.appendingPathComponent("Helpers")
    var isDir: ObjCBool = false
    if fm.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {
      return candidate.standardizedFileURL
    }
    let parent = dir.deletingLastPathComponent().standardizedFileURL
    if parent.path == dir.path { return nil }
    dir = parent
  }
}

/// Globs `**/*.swift` under `helpersDir`, skipping files prefixed with `_`.
internal func collectHelperSources(in helpersDir: URL) throws -> [URL] {
  guard
    let enumerator = FileManager.default.enumerator(
      at: helpersDir,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw CLIError(message: "could not enumerate \(helpersDir.path)")
  }

  var result: [URL] = []
  for case let url as URL in enumerator {
    let values = try url.resourceValues(forKeys: [.isRegularFileKey])
    guard values.isRegularFile == true else { continue }
    guard url.pathExtension == "swift" else { continue }
    guard !url.lastPathComponent.hasPrefix("_") else { continue }
    result.append(url.standardizedFileURL)
  }
  return result.sorted { $0.path < $1.path }
}

// MARK: - Build pipeline

/// Compiles helper sources into a per-key cache directory and returns the
/// directory plus a cache-hit flag. Returns nil when the helpers dir is empty.
internal func buildHelpers(
  helpersDir: URL,
  libPath: String
) throws -> CompiledHelpers? {
  let sources = try collectHelperSources(in: helpersDir)
  if sources.isEmpty { return nil }

  let key = try helpersCacheKey(sources: sources, libPath: libPath)
  let cacheRoot = try syntaxKitCacheRoot()
    .appendingPathComponent("helpers")
    .appendingPathComponent(key)
  let dylibPath = cacheRoot.appendingPathComponent("lib\(helpersModuleName).dylib").path

  let fm = FileManager.default
  if fm.fileExists(atPath: dylibPath) {
    return CompiledHelpers(outputDir: cacheRoot, cacheHit: true)
  }

  try fm.createDirectory(
    at: cacheRoot.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )

  let staging = cacheRoot.deletingLastPathComponent()
    .appendingPathComponent("tmp.\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)")
  try fm.createDirectory(at: staging, withIntermediateDirectories: true)

  do {
    try compileHelpers(sources: sources, into: staging, libPath: libPath)
  } catch {
    try? fm.removeItem(at: staging)
    throw error
  }

  // Atomic rename into the cache path. If a peer beat us to it (rename failed
  // because the destination now exists), keep theirs and drop ours.
  do {
    try fm.moveItem(at: staging, to: cacheRoot)
  } catch {
    try? fm.removeItem(at: staging)
    if !fm.fileExists(atPath: dylibPath) {
      throw error
    }
  }

  return CompiledHelpers(outputDir: cacheRoot, cacheHit: false)
}

private func compileHelpers(sources: [URL], into outDir: URL, libPath: String) throws {
  let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"
  let dylib = outDir.appendingPathComponent("lib\(helpersModuleName).dylib").path
  let modulePath = outDir.appendingPathComponent("\(helpersModuleName).swiftmodule").path

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  var args: [String] = [
    "swiftc",
    "-module-name", helpersModuleName,
    "-emit-module",
    "-emit-module-path", modulePath,
    "-parse-as-library",
    "-emit-library",
    "-o", dylib,
    "-suppress-warnings",
    "-I", libPath,
    "-L", libPath,
    "-lSyntaxKit",
    "-Xcc", "-I", "-Xcc", cShimsInclude,
    "-Xlinker", "-install_name",
    "-Xlinker", "@rpath/lib\(helpersModuleName).dylib",
    "-Xlinker", "-rpath", "-Xlinker", libPath,
  ]
  args.append(contentsOf: sources.map(\.path))
  process.arguments = args

  let stderrPipe = Pipe()
  process.standardOutput = FileHandle.nullDevice
  process.standardError = stderrPipe
  try process.run()
  process.waitUntilExit()

  let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
  guard process.terminationStatus == 0 else {
    let stderr = String(decoding: stderrData, as: UTF8.self)
    throw CLIError(
      message: """
        skitrun: failed to compile Helpers/ (exit \(process.terminationStatus))
        \(stderr)
        """)
  }
}

// MARK: - Cache key

private func helpersCacheKey(sources: [URL], libPath: String) throws -> String {
  var hasher = SHA256()
  hasher.update(data: Data(helpersCacheSchemaVersion.utf8))

  for source in sources {
    let data = try Data(contentsOf: source)
    hasher.update(data: Data(source.lastPathComponent.utf8))
    hasher.update(data: data)
  }

  if let swiftVersion = captureSwiftVersion() {
    hasher.update(data: Data(swiftVersion.utf8))
  }
  if let stamp = libStamp(libPath: libPath) {
    hasher.update(data: Data(stamp.utf8))
  }

  return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

internal func captureSwiftVersion() -> String? {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["swift", "--version"]
  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = FileHandle.nullDevice
  do { try process.run() } catch { return nil }
  process.waitUntilExit()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(decoding: data, as: UTF8.self)
}

internal func libStamp(libPath: String) -> String? {
  let dylib = "\(libPath)/libSyntaxKit.dylib"
  guard let attrs = try? FileManager.default.attributesOfItem(atPath: dylib) else { return nil }
  let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
  let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
  return "\(size)/\(Int(mtime))"
}

internal func syntaxKitCacheRoot() throws -> URL {
  if let xdg = ProcessInfo.processInfo.environment["XDG_CACHE_HOME"], !xdg.isEmpty {
    return URL(fileURLWithPath: xdg).appendingPathComponent("syntaxkit")
  }
  let home = NSHomeDirectory()
  #if os(macOS)
    return URL(fileURLWithPath: home)
      .appendingPathComponent("Library/Caches/com.brightdigit.SyntaxKit")
  #else
    return URL(fileURLWithPath: home).appendingPathComponent(".cache/syntaxkit")
  #endif
}
