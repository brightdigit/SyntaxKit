# String Literal Audit — SyntaxKit

**Date:** 2026-06-09
**Branch:** `research/swift-manifest-codegen`
**Scope:** All 208 `.swift` files across 5 modules (`SyntaxKit`, `skit`, `DocumentationHarness`, `SyntaxParser`, `TokenVisitor`). Markdown samples under `Documentation.docc` were excluded as illustrative, not product code.

**Goal:** Identify hardcoded string literals that should be moved into named constants, prioritized by extraction value (duplication × cross-module reach × domain meaning).

---

## Summary of counts

| Module | Files | Non-empty string literals |
|---|---|---|
| SyntaxKit | 150 | 292 |
| DocumentationHarness | 20 | 55 |
| TokenVisitor | 28 | 43 |
| skit | 6 | 41 |
| SyntaxParser | 4 | 19 |

Hotspots within SyntaxKit: `Expressions/` (80), `Collections/` (78), `Execution/` (47).

---

## Tier 1 — Highest value (duplicated + cross-cutting)

### 1.1 Empty-identifier fallback `.identifier("")` — ~30+ sites

The `DeclReferenceExprSyntax(baseName: .identifier(""))` "couldn't-resolve-expression" placeholder is the single most pervasive pattern in the codebase. It is a degenerate placeholder emitted whenever an `ExprSyntax` downcast fails.

**Recommendation:** Not just a constant — a shared factory (e.g. `ExprSyntax.placeholderReference` / `static let emptyDeclReferenceExpr`) so the fallback behavior lives in one place.

| Area | Locations (file:line) |
|---|---|
| Expressions (~13) | ConditionalOp.swift:42,52,62; FunctionCallExp.swift:58,136; Literal.swift:136,159,179,182; Literal+ExprCodeBlock.swift:97; NegatedPropertyAccessExp.swift:40; OptionalChainingExp.swift:44; PropertyAccessExp.swift:41; ReferenceExp.swift:47 |
| ControlFlow | Guard.swift:56,67; If+Conditions.swift:69,79; SwitchCase.swift:64; For.swift:47,55; Switch.swift:41 |
| Core / CodeBlocks | Core/CodeBlock.swift:52; CodeBlocks/CodeBlock+Generate.swift:51; CodeBlocks/CodeBlock+ExprSyntax.swift:52 |
| Utilities / Variables | Utilities/EnumCase+Syntax.swift:49; Utilities/Let.swift:50; Variables/Variable.swift:182 |
| Parameters / ErrorHandling | Parameters/ParameterExp.swift:44,53; ErrorHandling/Catch.swift:98; ErrorHandling/Throw.swift:45 |
| Collections | CodeBlock+DictionaryValue.swift:51; TupleAssignment.swift:174 |

### 1.2 Swift type names — ~35 sites

Universal Swift type tokens scattered across modules. The canonical inference table is `Expressions/Literal.swift`'s `typeName` switch.

**Recommendation:** Package-wide `TypeNames` caseless enum.

| String | Count | Locations (file:line) |
|---|---|---|
| `"Any"` | 18 | Collections/TupleLiteralArray.swift:52-59; Collections/DictionaryLiteral.swift:47,48; Collections/ArrayLiteral.swift:47; Expressions/ClosureParameter.swift:45; Expressions/ClosureType.swift:44; Expressions/Literal.swift:67,80-102 |
| `"Void"` | 3 | Expressions/ClosureType.swift:67,95,127 |
| `"String"` | 4 | Collections/TupleLiteralArray.swift:50; Expressions/Literal.swift:61,73; Variables/Variable+LiteralInitializers.swift:63 |
| `"Int"` | 4 | Collections/TupleLiteralArray.swift:47; Expressions/Literal.swift:63,72; Variables/Variable+LiteralInitializers.swift:80 |
| `"Double"` | 4 | Collections/TupleLiteralArray.swift:48; Expressions/Literal.swift:62,74; Variables/Variable+LiteralInitializers.swift:114 |
| `"Bool"` | 4 | Collections/TupleLiteralArray.swift:49; Expressions/Literal.swift:65,75; Variables/Variable+LiteralInitializers.swift:97 |
| `"Any?"` | 3 | Collections/TupleLiteralArray.swift:51; Expressions/Literal.swift:64,76 |
| `"[Any]"` | 2 | Collections/ArrayLiteral.swift:45; Expressions/Literal.swift:92 |
| `"[Any: Any]"` | 3 | Collections/DictionaryExpr.swift:44; Collections/DictionaryLiteral.swift:45; Expressions/Literal.swift:99 |
| `"[String: Any]"` | 1 | Collections/DictionaryExpr.swift:46 |
| `"[String]"` | 1 | Collections/Array+LiteralValue.swift:34 |
| `"[Int: String]"` | 1 | Collections/Dictionary+LiteralValue.swift:34 |

### 1.3 Duplicated string-escape block — verbatim copy in 2 files

`Collections/Array+LiteralValue.swift` and `Collections/Dictionary+LiteralValue.swift` contain an identical escape map: `\` → `\\`, `"` → `\"`, `\n` → `\n`, `\r` → `\r`, `\t` → `\t` (lines 47–51 in each).

**Recommendation:** One shared `String.escapedForSwiftLiteral()` helper. (Related-but-distinct escape logic also lives in `Execution/WrappedSource.swift:105-106` and `TokenVisitor/TriviaPiece.swift`.)

### 1.4 Whitespace / separators — most cross-cutting tokens

| String | Count | Locations |
|---|---|---|
| `"\n"` | 12+ | skit/Skit.Run+Render.swift (stderr writes), skit/Skit+Run.swift:104,153; DocumentationHarness/CodeBlockExtraction.swift:141; TokenVisitor/TriviaPiece.swift:63; Collections/Array+LiteralValue.swift:49, Dictionary+LiteralValue.swift:49; Execution/WrappedSource.swift:99 |
| `", "` | 10+ | Collections (ArrayLiteral, Array+LiteralValue, Dictionary+LiteralValue, TupleLiteralArray, DictionaryLiteral, DictionaryExpr); Expressions (ClosureType.swift:91, Literal.swift:88) |

---

## Tier 2 — Domain literals worth naming

### Operators (Expressions, Patterns)
| String | Locations |
|---|---|
| `"+="` (defined twice independently) | Expressions/Infix.swift:40; Expressions/PlusAssign.swift:53 |
| `"-="`, `"=="`, `"!="`, `">"`, `"<"` | Expressions/Infix.swift:36-41 |
| `"!"` (prefix negation) | Expressions/NegatedPropertyAccessExp.swift:45 |
| `"..<"`, `"..."` (range operators) | Patterns/Range+PatternConvertible.swift:39,58 |

### skit CLI args & swiftc flags
| String | Locations |
|---|---|
| `"swift"` (executable name) | skit/Skit.Run+Render.swift:160; skit/Subprocess.Configuration+Swift.swift:60 |
| `"--version"`, `"--timeout"` | skit/Skit.Run+Render.swift:163; skit/Skit+Run.swift:73,87 |
| `"run"`, `"parse"`, `"output"`, `"lib"`, `"no-cache"`, `"no-toolchain-check"` | skit/Skit+Run.swift:47,55,62,67,79; skit/Skit+Parse.swift:37 |
| `"-I"`, `"-L"`, `"-lSyntaxKit"`, `"-Xcc"`, `"-Xlinker"`, `"-rpath"`, `"-suppress-warnings"` | skit/Subprocess.Configuration+Swift.swift:50-57 |
| `"SKIT_LIB_DIR"` (env key) | skit/Skit+Run.swift:99 |
| `"skit: "` (stderr prefix, 5+ sites) | skit/Skit.Run+Render.swift:116,126,147,170; skit/Skit+Run.swift:153; also Execution/Runner.swift:197, ToolchainCheckResult.swift:57,64 |

### Execution paths / env / formats
| String | Locations |
|---|---|
| `"output.swift"` (3×) | Execution/OutputCache.swift:116,123,139 |
| `"swift"` (file extension filter) | Execution/FileManager+Execution.swift:84 |
| `"SyntaxKit"` (dylib product, 2×) | Execution/FileManager+Execution.swift:39,46 |
| `lib\(self).so` / `lib\(self).dylib` | Execution/String+DylibFilename.swift:36,38 |
| `"XDG_CACHE_HOME"`, `"syntaxkit"` cache dir | Execution/ProcessInfo+SyntaxKitCacheRoot.swift:37,38; OutputCache.swift:53 |
| `"SKIT_"` / `"SYNTAXKIT_"` env prefixes | Execution/OutputCache.swift:105 |
| `"Library/Caches/com.brightdigit.SyntaxKit"`, `".cache/syntaxkit"`, `"outputs"` | Execution/OutputCache.swift:51,53,74 |
| `"lib"`, `"lib/skit"` | Execution/Bundle+ResolveLibPath.swift:55,61 |
| `"%016x"` (hash format), `"swift-version.txt"` | Execution/ContentHasher.swift:57; ToolchainCheckResult.swift:34 |

### DocumentationHarness markers & fences
| String | Locations |
|---|---|
| `<!-- skip-test -->`, `<!-- no-test -->`, `<!-- incomplete -->`, `<!-- example-only -->` | CodeBlockExtraction.swift:152-155 |
| ` ```swift ` (open), ` ``` ` (close) | CodeBlockExtraction.swift:94,96 |
| `"md"` (default doc extension) | Validator.swift:38 |
| `"import SyntaxKit"` (2×), `"import Foundation"`, `"Package.swift"`, `"@main"` | CodeSyntaxValidator.swift:44,49,62,63 |
| skip dirs: `".build"`, `"node_modules"`, `".git"`, `".svn"`, `"DerivedData"`, `"build"`, `".swiftpm"` | FileManager+Documentation.swift:38-46 |

### Comment trivia & misc tokens
| String | Locations |
|---|---|
| `"// "`, `"/// "`, `"///"` | Core/Line+Trivia.swift:39,43,45 |
| `"_"` (wildcard / unnamed label, 8+ sites) | Parameters/Parameter.swift:50,77,110; Expressions/Literal.swift:139; Literal+ExprCodeBlock.swift:72; Collections/TupleLiteralArray.swift:86; CodeBlocks/CodeBlockItemSyntax.Item.swift:53 |
| `"."` (member separator) | ErrorHandling/Catch.swift:48; Utilities/EnumCase.swift:46; TokenVisitor/TreeNodeProtocol+Extensions.swift:189; DocumentationHarness (extension join) |
| `"self"` (capture fallback) | Expressions/CaptureInfo.swift:56,67 |
| `"Syntax"` (suffix stripped) | TokenVisitor/Syntax.swift:54 |
| TriviaPiece chars: space, `\t`, `\n`, `\`, `#` | TokenVisitor/TriviaPiece.swift:57-69 |

---

## Tier 3 — Deprecation messages (dedup only, not reuse)

Single-purpose but **duplicated verbatim** — collapsing each to one local constant removes the copies.

| Message | Copies | Location |
|---|---|---|
| `"Use Infix(target, \"+=\", value) instead."` | 6 | Expressions/PlusAssign.swift:71,80,89,97,105,113 |
| `"Use parse(code:) which returns [TreeNode] directly instead of JSON"` | 3 | SyntaxParser/SyntaxResponse.swift:44,51,59 |
| `"Use separate lhs and rhs parameters for compile-time safety"` | 1 | Expressions/Infix.swift:128 |
| `"Use ParameterExp(name:value:) ..."` / `"Use ParameterExp(unlabeled:) ..."` | 1 ea. | Parameters/ParameterExp.swift:82,98 |
| `"Use Parameter(unlabeled:type:) ..."` | 1 | Parameters/Parameter.swift:117 |
| `"Use While(kind:condition:) ..."` / `"Use While(VariableExp(condition)...)"` | 1 ea. | ControlFlow/While.swift:130,151 |

Plus runtime error messages worth extracting for testability: `Infix` operand errors (Infix.swift:58,60), `Parenthesized` arity (Utilities/Parenthesized.swift:58), Execution path/IO errors (Runner.swift, Bundle+ResolveLibPath.swift:47, FileManager+Execution.swift:68, RunInput.swift:53,57).

---

## Already extracted (no action needed)

- `SyntaxParser/SyntaxParser.swift` — `fold`, `showMissing`
- `TokenVisitor/StructureProperty.swift` — `element`, `count`, `nilValue`
- `TokenVisitor/String.swift` — `String.empty`, `String.defaultFileName`
- `skit/Subprocess.Configuration+Swift.swift` — `stdoutLimitBytes`, `stderrLimitBytes`

---

## Notable non-findings

- **Token-kind strings are never hardcoded.** Expected literals like `"keyword"`, `"identifier"`, `"invisible"` come from interpolating `token.tokenKind` — they appear only in doc-comments. No work needed.
- **`DocumentationHarness/PackageValidator.swift` and `CompilationResult.swift`** literals sit in `@available(*, unavailable)` dead code — low priority.

---

## Suggested target structure

A small set of caseless enums plus one factory helper:

- **Package-wide** (in `Core/` or `Utilities/`): `TypeNames`, `Operators`, `Keywords`/`Tokens`, `Separators`.
- **`ExprSyntax.placeholderReference`** factory for the Tier 1.1 empty-identifier fallback.
- **Module-local** static constants for Execution paths/env, skit CLI args, and DocumentationHarness markers.

**Recommended order:** Tier 1 first (biggest payoff, touches the most files), then Tier 2 by module, then Tier 3 dedup.
