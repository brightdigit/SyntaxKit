# POC Step 1 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §6 step 1. Goal: prove the `swift`-script + framework-search-path mechanism works for SyntaxKit, that a result-builder closure spliced from user text compiles cleanly, and measure cold-start cost.

## TL;DR — Approach is viable

- **Cold start: ~720ms** real wall-clock for `xcrun swift Input.wrapped.swift -lSyntaxKit …` on M-series macOS with the dylib + module files unbacked by the OS page cache.
- **Warm: ~110ms** for subsequent runs.
- **Pure-DSL `Input.swift` spliced into `Group { … }`** in a generated wrapper compiles and runs end-to-end, producing the expected Swift source.
- **Bundled-dylib distribution is real and viable.** The only flags the CLI has to assemble are `-I`, `-L`, `-lSyntaxKit`, `-Xlinker -rpath -Xlinker <lib>` and one new requirement: `-Xcc -I -Xcc <C-shim-include-dir>` (see §3 finding).
- **SyntaxKit dylib weight:** 25 MB debug → 18 MB release → **9.3 MB stripped release**. The 9.3 MB number is the one that matters for distribution and is well within range of a normal CLI binary.

## 1. What was run

Built the dylib by temporarily flipping the SyntaxKit library product to `type: .dynamic` in `Package.swift`, ran `swift build`, copied the artifacts into a `/tmp/syntaxkit-poc/lib/` staging dir, then reverted the package manifest.

Wrote a pure-DSL `Input.swift`:

```swift
import SyntaxKit  // optional; only for IDE

Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}

Struct("Pet") {
    Variable(.let, name: "kind", type: "String")
}
```

And a hand-rolled `Input.wrapped.swift`:

```swift
import SyntaxKit

let __syntaxkit_root = Group {
    Struct("Person") {
        Variable(.let, name: "name", type: "String")
        Variable(.let, name: "age", type: "Int")
    }
    Struct("Pet") {
        Variable(.let, name: "kind", type: "String")
    }
}

print(__syntaxkit_root.generateCode())
```

Invoked with:

```
xcrun swift \
  -I lib -L lib -lSyntaxKit \
  -Xcc -I -Xcc lib/_SwiftSyntaxCShims-include \
  -Xlinker -rpath -Xlinker $(pwd)/lib \
  Input.wrapped.swift
```

Output (verbatim):

```
struct Person {
let name  : String
let age  : Int

}
struct Pet {
let kind  : String

}
```

(Whitespace artifacts are SyntaxKit's `generateCode()` output as-is — out of scope for this POC.)

## 2. Timings

Three back-to-back runs after a cold first run:

| Run | real | user | sys |
| --- | ---: | ---: | ---: |
| cold (first) | 0.72s | 0.77s | 0.29s |
| warm 1 | 0.14s | 0.08s | 0.04s |
| warm 2 | 0.11s | 0.07s | 0.02s |
| warm 3 | 0.11s | 0.07s | 0.02s |

Hardware: Apple Silicon mac. Cold start is dominated by loading SyntaxKit + SwiftSyntax dylibs from disk; once cached, the swift interpreter just compiles a tiny script. For a per-file CLI invocation this is well inside the "feels instant" budget.

## 3. New design finding: C-shim include path

Without `-Xcc -I -Xcc <_SwiftSyntaxCShims/include>`, the script compile fails with:

```
<unknown>:0: error: missing required module '_SwiftSyntaxCShims'
```

SyntaxKit transitively depends on SwiftSyntax which has a C-shims target whose module map lives at `swift-syntax/Sources/_SwiftSyntaxCShims/include/module.modulemap`. The CLI's bundled-binary distribution layout (§5 of the design doc) must include this header directory, not just the `.dylib` and `.swiftmodule` files. Updated the design doc to reflect this.

## 4. New design finding: `if` inside `Group` is broken in SyntaxKit today

A wrapped input containing a conditional in the builder:

```swift
let __syntaxkit_root = Group {
    if true {
        Struct("A") { Variable(.let, name: "x", type: "Int") }
    }
}
```

fails with:

```
error: failed to produce diagnostic for expression; please submit a bug report
let __syntaxkit_root = Group {
                       ^
```

`CodeBlockBuilderResult` declares both `buildEither(first:)` / `buildEither(second:)` and `buildOptional` (`Sources/SyntaxKit/CodeBlocks/CodeBlockBuilderResult.swift:46-58`), so the API surface *says* `if`/`else` is supported. The compiler crash is a Swift type-checker timeout — likely from the `any CodeBlock...` variadic overload combined with `buildEither` overload resolution. No test in `Tests/SyntaxKitTests/Unit/` exercises an `if` inside `Group { … }`, which is why this hasn't been caught.

**Implication for the CLI design:** non-blocking. v1 can document "no conditionals in input files yet" and ship; the underlying SyntaxKit fix is independent. Worth filing as a separate issue.

## 5. Confirmed: hoisted imports work

A wrapped input with both `import SyntaxKit` and `import Foundation` at the top compiles fine and `UUID`/`Date` resolve in the rendered struct fields. The CLI's hoist-imports step (design §3) is safe.

## 6. Not yet retired

- **Stderr/stdout interleaving under load.** Need a load test (large input → tons of output → confirm captured stdout is intact and stderr doesn't bleed in).
- **Linux behavior.** Step 7 of the POC ladder. Same `swift -I -L -l` flag set should work; framework-search paths (`-F`) become a no-op.
- **`@main` and other top-level forms.** Not relevant for the wrapper because we always control the wrapper's shape, but if users ever paste a class/extension declaration directly into `Input.swift` we need to reject it cleanly.

## 7. Updates to the design doc to make from this POC

- §5 distribution layout: add `Sources/_SwiftSyntaxCShims/include/` to the bundled `lib/` contents.
- §3 spawn command: include the `-Xcc -I -Xcc <…>` flag.
- §7 open questions: SyntaxKit dylib size measured at 25 MB debug, 18 MB release, 9.3 MB release+stripped (`strip -x`). Warm performance identical between debug and release builds.
- §7 open questions: add tracking note for the `if`-in-`Group` Swift compiler bug.
