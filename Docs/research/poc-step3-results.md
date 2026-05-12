# POC Step 3 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §6 step 3. Goal: extend `skitrun` to walk a directory of `.swift` inputs, mirror the relative paths into an output directory, and run the per-file work concurrently with a sane cap.

## What changed

`skitrun` now accepts a directory as input:

```
skitrun InputDir/ -o OutDir/
```

When the input is a directory, the existing single-file work is hoisted into a `processFile(inputPath:libPath:)` helper. The new `runDirectory(...)` driver walks the input with `FileManager.enumerator`, fan-outs the per-file work over `withTaskGroup`, and writes successes into mirrored paths under `OutDir/`. Single-file mode is unchanged.

Three small conventions ride along:

- **`_`-prefix skip rule.** `_Helpers.swift`, `_Shared.swift`, etc. are not processed. (Confirmed against `_HelperShouldBeSkipped.swift` containing deliberately-invalid Swift — skitrun didn't try to compile it.)
- **`activeProcessorCount` concurrency cap.** The task group keeps that many in-flight `swift` spawns at a time, draining + refilling as each finishes.
- **Tuist-analog partial semantics.** Successful files are *always* written, even when other files in the same batch fail. The CLI exits non-zero if any failed and prints a `skitrun: N/M succeeded` summary to stderr.

## Verified flows

1. **Happy path.** A `codegen/` tree with `Models/Person.swift`, `Models/Pet.swift`, `Audit/Snapshot.swift` (the last with a hoisted `import Foundation`) produces a mirrored `out/Models/{Person,Pet}.swift` + `out/Audit/Snapshot.swift`. Total wall time 1.41s for 3 files (vs. 0.72s baseline cold-start for one).
2. **Skip rule.** `codegen/_HelperShouldBeSkipped.swift` contains the literal line `this is not valid swift`. It is not visited, the rest of the tree processes cleanly.
3. **Partial failure.** Adding a `Models/Bad.swift` with `type: TypeThatDoesNotExist` produces:
   ```
   ---- /tmp/skitrun-folder-test/codegen/Models/Bad.swift ----
   /tmp/skitrun-folder-test/codegen/Models/Bad.swift:4:37: error: cannot find 'TypeThatDoesNotExist' in scope
   …
   skitrun: 3/4 succeeded
   ```
   Exit code 1. Person/Pet/Snapshot still written.
4. **Single-file regression.** Both `skitrun Input.swift` (stdout) and `skitrun Input.swift -o Out.swift` (file) still work after the refactor.

## Parallelism observations

A quick timing on 3 parallel files vs. 1 cold-start baseline:

| | wall time |
| --- | ---: |
| 1 file, cold | 0.72s |
| 3 files, cold, `withTaskGroup` cap = `activeProcessorCount` | 1.41s |

That's well below 3×0.72 = 2.16s, confirming the parallelism is buying something — but also clearly slower than 3×0.11 = 0.33s warm, meaning successive `swift` invocations don't fully share OS file-cache benefits within a single batch run. (Each spawn still pays its own compile cost; the dylib pages are warm after the first, but compile work isn't deduplicated.) For larger batches we'd want to measure where the curve goes — and eventually pull the work into a single long-lived `swift` process driving all inputs, to skip the per-file compile overhead entirely. Out of scope for v1.

## What's next

Step 4 — bundled-binary release. The first real systems-integration challenge: how the `lib/` directory ships next to the `skitrun` binary across `swift build`, `swift run`, and `brew install`. Today users have to run `Docs/research/poc-step1.sh` to stage `/tmp/syntaxkit-poc/lib/`; that has to become "user installs the CLI, it just works."
