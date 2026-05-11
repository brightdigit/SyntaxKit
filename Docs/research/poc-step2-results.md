# POC Step 2 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §6 step 2. Goal: wrap the hand-driven flow from step 1 inside an actual CLI executable that parses imports with SwiftSyntax, generates the wrapper, spawns `swift`, and forwards output/errors.

## What landed

New executable target `skitrun` (POC name; final CLI name TBD) at `Sources/skitrun/Main.swift`. Single file, ~180 lines. Depends only on `SwiftSyntax` + `SwiftParser` — does **not** depend on SyntaxKit, since the host doesn't render anything itself.

## Usage

```
skitrun <input.swift> [-o <output.swift>] [--lib <lib-dir>]
```

`--lib` defaults to `/tmp/syntaxkit-poc/lib` so it works against the artifacts produced by [`poc-step1.sh`](./poc-step1.sh) without further flags.

Build it once: `swift build --product skitrun`. The binary lands at `.build/<triple>/debug/skitrun`.

## Verified flows

1. **Default (stdout):** `skitrun Input.swift` prints rendered Swift to stdout.
2. **File output:** `skitrun Input.swift -o Out.swift` writes the file atomically.
3. **Hoisted imports:** an input with `import Foundation` at the top compiles cleanly; `UUID`/`Date` resolve in the rendered struct.
4. **Compiler diagnostics map to the input file.** A deliberate `type: NonexistentType` in `InputError.swift:4` produces:
   ```
   /tmp/syntaxkit-poc/InputError.swift:4:37: error: cannot find 'NonexistentType' in scope
   ```
   The path and line are correct — confirming `#sourceLocation` is doing the work end-to-end.

## How the wrap works

`SwiftParser.Parser.parse(source:)` produces a `SourceFileSyntax`. We walk `tree.statements`:

- Every leading `ImportDeclSyntax` is collected for hoisting.
- The first non-import statement marks the start of the body.
- Everything from that byte offset forward is the body, copied verbatim.

The wrapper is then:

```swift
import SyntaxKit
<hoisted imports>

let __skitrun_root = Group {
#sourceLocation(file: "<absolute-input-path>", line: <first-body-line>)
<body verbatim>
#sourceLocation()
}

print(__skitrun_root.generateCode())
```

`#sourceLocation` is what gives us diagnostic fidelity for free — the Swift compiler honors it and rewrites file/line in every error/warning emitted from the body range. No manual stderr line-number arithmetic needed.

## Spawn shape

`Foundation.Process` invoking `/usr/bin/env swift` with the exact flag set from POC step 1, captured into `stdoutPipe` and `stderrPipe`. Stdout is written verbatim to the output destination. Stderr is forwarded after one fix-up: any remaining literal `/<tmp>/skitrun-<UUID>/Input.wrapped.swift` references (those outside the `#sourceLocation` range — i.e. errors in the preamble itself) get rewritten to the input path.

## Surface limits worth knowing

- **Snippet gutter line numbers in diagnostics show wrapper line numbers, not input line numbers.** The compiler maps the *file/line* in the diagnostic header via `#sourceLocation` but shows the surrounding source snippet from the actual file with its actual line numbers. The path and starting line are correct (navigable), but the gutter `7 |` / `8 |` markers may not match the input's line numbering. Cosmetic; doesn't affect navigation.
- **No timeout yet.** The design calls for a 60s default. Adding `Process.terminate(after:)` is a step 6 (cache) sibling concern.
- **Stdin / stderr interleaving under load not tested.** Step 7 territory.
- **`if`-in-`Group` still crashes the compiler** ([#155](https://github.com/brightdigit/SyntaxKit/issues/155)). Independent SyntaxKit bug; `skitrun` would happily pass such an input through, but the spawned `swift` would fail with the same opaque diagnostic from step 1.

## What's next

The natural step 3 is folder mode (walk `InputDir/**/*.swift`, mirror paths into `OutputDir/`). All the per-file work is already in place — folder mode is just iteration + concurrency-limited fan-out + a `_`-prefix skip rule. Modest engineering, low risk.

After that, step 4 (bundled-binary release) is where the design hits its biggest remaining systems-integration question: how to actually ship the `lib/` directory next to the binary across SwiftPM build, install, and `brew` distribution.
