//
//  Skit.swift
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

import ArgumentParser

/// The `skit` CLI entry point.
///
/// `Skit` itself is just an ArgumentParser shell that wires up two subcommands:
/// `Run` (the default, rendering SyntaxKit DSL into Swift source) and `Parse`
/// (the inverse, reading Swift source on stdin and emitting JSON). Their bodies
/// live in `Skit+Run.swift` and `Skit+Parse.swift` respectively.
@main
internal struct Skit: AsyncParsableCommand {
  /// The top-level command name as invoked on the command line.
  internal static let commandName = "skit"

  /// Name of the `swift` executable resolved on `PATH`. Shared by the
  /// toolchain-version capture and the Subprocess `swift` configuration.
  internal static let swiftExecutableName = "swift"

  internal static let configuration = CommandConfiguration(
    commandName: commandName,
    abstract: "Render SyntaxKit DSL into Swift source, or parse Swift into JSON.",
    subcommands: [Run.self, Parse.self],
    defaultSubcommand: Run.self
  )
}
