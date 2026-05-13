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

#if canImport(Subprocess)

  import Foundation
  import Subprocess

  /// Hardcoded module name for the user's `Helpers/` compilation output. Inputs
  /// reach the compiled helpers via `import SyntaxKitHelpers`.
  internal let helpersModuleName = "SyntaxKitHelpers"

  /// Platform-specific shared-library filename for a Swift library product.
  internal func dylibFilename(forLibrary name: String) -> String {
    #if os(Linux)
      return "lib\(name).so"
    #else
      return "lib\(name).dylib"
    #endif
  }

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
  ///
  /// Concurrent invocations are tolerated via the staging-dir + atomic-rename
  /// pattern: if two processes race to compile the same key, the loser's
  /// rename fails and we keep the winner's artefact.
  internal func buildHelpers(
    helpersDir: URL,
    libPath: String
  ) async throws -> CompiledHelpers? {
    // Collect helper sources. An empty Helpers/ dir is "no helpers" rather
    // than an error — the caller will fall back to no-helpers mode.
    let sources = try collectHelperSources(in: helpersDir)
    if sources.isEmpty { return nil }

    // Compute the content-keyed cache path. The dylib's presence under that
    // path is what makes a build "cached".
    let key = try await helpersCacheKey(sources: sources, libPath: libPath)
    let cacheRoot = try syntaxKitCacheRoot()
      .appendingPathComponent("helpers")
      .appendingPathComponent(key)
    let dylibPath =
      cacheRoot
      .appendingPathComponent(dylibFilename(forLibrary: helpersModuleName)).path

    // Cache hit: artefact already present, skip the whole compile.
    let fm = FileManager.default
    if fm.fileExists(atPath: dylibPath) {
      return CompiledHelpers(outputDir: cacheRoot, cacheHit: true)
    }

    // Ensure the parent of the cache key dir exists. We don't create the
    // key dir itself — the atomic move below installs it.
    try fm.createDirectory(
      at: cacheRoot.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    // Compile into a per-pid + uuid staging dir, then atomically rename into
    // place. This is what lets concurrent skit invocations co-exist safely.
    let staging = cacheRoot.deletingLastPathComponent()
      .appendingPathComponent(
        "tmp.\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)")
    try fm.createDirectory(at: staging, withIntermediateDirectories: true)

    // Run swiftc into the staging dir. Clean up on failure so we don't leak
    // half-baked artefacts in the cache root.
    do {
      try await compileHelpers(sources: sources, into: staging, libPath: libPath)
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

  /// Invokes `swiftc` to build `sources` into a Swift module + dylib under
  /// `outDir`. The dylib is named `lib<helpersModuleName>.{dylib,so}` and the
  /// module file is `<helpersModuleName>.swiftmodule`. Output (stdout)
  /// is discarded; stderr is captured for the error path.
  private func compileHelpers(sources: [URL], into outDir: URL, libPath: String) async throws {
    let cShimsInclude = "\(libPath)/_SwiftSyntaxCShims-include"
    let dylib = outDir.appendingPathComponent(dylibFilename(forLibrary: helpersModuleName)).path
    let modulePath = outDir.appendingPathComponent("\(helpersModuleName).swiftmodule").path

    // Base swiftc arguments: emit a library + module file linking against
    // libSyntaxKit, with rpath set so the dylib can find libSyntaxKit at
    // load time.
    var args: [String] = [
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
      "-Xlinker", "-rpath", "-Xlinker", libPath,
    ]
    #if !os(Linux)
      // @rpath install_name is macOS-only; on Linux SONAME isn't needed because
      // we use rpath-based loading and the dylib lives in a cache path that's
      // known at link time.
      args.append(contentsOf: [
        "-Xlinker", "-install_name",
        "-Xlinker", "@rpath/\(dylibFilename(forLibrary: helpersModuleName))",
      ])
    #endif
    // Append source files last so the leading flags apply to all of them.
    args.append(contentsOf: sources.map(\.path))

    // Spawn swiftc. Stderr is captured (1 MiB cap) so a compile failure can
    // surface the diagnostic verbatim in a CLIError.
    let result = try await run(
      .name("swiftc"),
      arguments: Arguments(args),
      output: .discarded,
      error: .string(limit: 1 * 1_024 * 1_024)
    )

    guard result.terminationStatus.isSuccess else {
      let stderr = result.standardError ?? ""
      throw CLIError(
        message: """
          skit: failed to compile Helpers/ (\(result.terminationStatus))
          \(stderr)
          """)
    }
  }

  // MARK: - Cache key

  /// Content-addressed cache key mixing schema version, each helper source's
  /// filename + bytes, `swift --version`, and the libSyntaxKit stamp.
  private func helpersCacheKey(sources: [URL], libPath: String) async throws -> String {
    var hasher = ContentHasher()
    hasher.update(data: Data(helpersCacheSchemaVersion.utf8))

    // Filename matters as well as bytes — two same-content files with
    // different names produce different symbols.
    for source in sources {
      let data = try Data(contentsOf: source)
      hasher.update(data: Data(source.lastPathComponent.utf8))
      hasher.update(data: data)
    }

    // Toolchain + dylib stamp invalidate on cross-version or in-place rebuild.
    if let swiftVersion = await captureSwiftVersion() {
      hasher.update(data: Data(swiftVersion.utf8))
    }
    if let stamp = libStamp(libPath: libPath) {
      hasher.update(data: Data(stamp.utf8))
    }

    return hasher.finalize()
  }

  /// Verbatim `swift --version` output, or nil on spawn failure. Capped at 4 KiB.
  internal func captureSwiftVersion() async -> String? {
    let result = try? await run(
      .name("swift"),
      arguments: ["--version"],
      output: .string(limit: 4_096),
      error: .discarded
    )
    return result?.standardOutput
  }

  /// `<size>/<mtime>` fingerprint of the bundled libSyntaxKit dylib, or nil
  /// if unreadable. Catches in-place rebuilds without a version bump.
  internal func libStamp(libPath: String) -> String? {
    let dylib = "\(libPath)/\(dylibFilename(forLibrary: "SyntaxKit"))"
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: dylib) else { return nil }
    let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
    let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    return "\(size)/\(Int(mtime))"
  }

  /// Root for all skit caches. Honours `XDG_CACHE_HOME`, else macOS
  /// `~/Library/Caches/...` or Linux `~/.cache/syntaxkit`.
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

#endif
