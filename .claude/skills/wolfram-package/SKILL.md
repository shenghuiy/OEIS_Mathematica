---
name: wolfram-package
description: Context rules for the Wolfram packages in src/wolfram/*.wl and their tests in test/wolfram/*.wlt — what goes before Begin["`Private`"], how symbols leak into the shared OEIS` context, the ::shdw failures that follow, and where to run Wolfram code (local kernel first, cloud only without FunctionCompile). Use when adding or editing a package or a .wlt file, running Wolfram code, or when a test fails on a ::shdw message.
---

# Wolfram package contexts

Every package is `BeginPackage["OEIS`"]` and shares the public `OEIS`` context with the others, and every test file runs in the same kernel as the rest when the suite is run with `TestReport /@ FileNames["*.wlt", "test/wolfram"]`. A symbol one file leaks is visible to all of them.

## How a symbol gets its context

The kernel creates a symbol when the line that names it is **parsed**, in the `$Context` current at that moment. Between `BeginPackage["OEIS`"]` and `Begin["`Private`"]` that is `OEIS``; after `Begin` it is `OEIS`Private``. This covers every name on the line: the function, its pattern variables, the helpers it calls.

Once a name exists in `OEIS``, a later line in the Private section that uses the same name resolves to the public symbol (`$ContextPath` holds `OEIS``) instead of creating a private one.

At `EndPackage[]`, `OEIS`` goes onto `$ContextPath`. If a name in `OEIS`` already exists in `Global`` (made by a test file that ran earlier), the kernel issues `name::shdw`, and any `VerificationTest` that loads the package fails on the unexpected message.

The case that happened: `A399539.wl` had `A399539[n_Integer?Positive] := isokSeg[n, 2^16]` before `Begin`, which created `OEIS`n` and `OEIS`isokSeg` (the compiled helper defined later in Private became public too). `A101198.wlt` uses `n` as an iterator and sorts first, so `A399539.wlt`'s `load-package` failed on `n::shdw`.

## Package layout

- The public section holds `name::usage = "..."` lines only, one per public function. They create exactly the public symbols.
- Every definition, helper, compiled function and message definition goes after `Begin["`Private`"]`, with the public function defined after the helpers it calls.
- `OEIS`Private`` is shared by all packages too, so give global helpers names specific to the package (`strA157196`, `bsPartitionQ`, `rankCountSum`), and keep loop and pattern variables local (`Module`, `Function`, patterns).
- Keep the notebook cell markers (`(* ::Subsection:: *)` and the like) intact.

## Tests

- Call public functions by their short name (`A399539[...]`, `TopSpinSolve[...]`), without `OEIS``. `TestReport` reads and evaluates a `.wlt` one test at a time, so once the `load-package` test has run, `OEIS`` is on `$ContextPath` and the short name resolves there. The `load-package` test itself must name no public symbol: a name parsed before the package loads lands in `Global``, and `EndPackage[]` then fails on `::shdw`.
- Call private helpers by full name, `OEIS`Private`helper[...]`. That name is created in exactly that context, so a misspelled or moved helper shows up as a failing test instead of a new symbol.
- Context names inside strings keep their prefix (`Names["OEIS`TopSpin*"]`, `NameQ["OEIS`n"]`): they are the checks that nothing leaks into `OEIS``.
- Ordinary short names (`n`, `k`, `p`) are fine in tests: they land in `Global``, which only causes trouble when a package leaks the same name into `OEIS``.
- The docs follow the same rule: examples `Get` the package and then use short public names, and only private helpers are written `OEIS`Private`helper`. The PostToolUse hook `.claude/hooks/wolfram-short-public-names.js` flags `OEIS`Name` outside strings and comments after an edit to a `.wlt` file, a `docs/` page or a README.

## Running Wolfram code

Run on a local kernel whenever one is available. That means `wolframscript` (the paths are in `CLAUDE.md`) or the Wolfram MCP evaluator and `TestReport` tools, which also start local kernels.

- With `wolframscript -file`, `FunctionCompile` draws a progress box of `|` and `-` lines on every compile. Pipe through `grep -v '^ *[|-]'` to see only the real output.
- Fall back to the Wolfram Cloud (`wolframscript -cloud -code '...'`, after a one-time `wolframscript -authenticate`) only when no local kernel can start, for example when no license is free. Use it only for code that never reaches `FunctionCompile`, directly or through a package it loads (`grep FunctionCompile src/wolfram/*.wl` lists those packages). Compiled code waits for a local kernel.

## Done when

In a fresh kernel, `Get` the package and check that `Names["OEIS`*"]` lists exactly the names that have a `::usage` line. Then run the whole suite in one kernel; a `::shdw` message anywhere means a package is leaking. The package's page in `docs/` is done when it passes the checks in the `docs-page` skill.
