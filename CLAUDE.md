# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

Two independent code bases share the repo; only the Java one has a build, and only it runs in CI.

- `src/java/CarrylessArithmetic.java` — carry-less ("dismal") arithmetic on decimal strings, a port of David Applegate's 2003 C program. Operands and results are `String`s; divisor/divide search uses a `ToIntFunction<String>` callback (a negative return stops the search). Also callable from Mathematica via J/Link.
- `src/wolfram/*.wl` — standalone Wolfram Language packages, one per OEIS sequence/topic (`A003785`, `A157196`, `A399539`, `DivisorSigmaInverse`). Each is `BeginPackage["OEIS`"]` with public symbols in the shared `OEIS`` context and helpers in `` `Private` ``, written as Mathematica notebook-style source (`(* ::Subsection:: *)` markers, so keep those cell markers intact when editing).
- `docs/` — one Markdown explanation per source file, indexed from the top-level `README.md`. When changing a `.wl` or the Java class, update its doc page.
- `test/java/` — JUnit 5 tests; `expected/` holds reference output from the original C program, `results/` holds recorded surefire reports.
- `test/wolfram/` — one `.wlt` file (`VerificationTest` cases) per `.wl` package.

## Commands

Maven is configured with non-standard directories (`src/java`, `test/java`), Java release 11.

```bash
mvn test                                        # all tests (CI runs this on Java 11 and 21)
mvn test -Dtest=CarrylessArithmeticTest#methodName   # single test
```

`mvn test` writes reports to `target/surefire-reports/` (gitignored). To update the recorded results, copy `CarrylessArithmeticTest.txt` and `TEST-CarrylessArithmeticTest.xml` into `test/java/results/`. See `test/java/README.md` for regenerating `expected/` from the C program.

The Wolfram tests are not part of Maven or CI. Run them in a Wolfram kernel with `TestReport /@ FileNames["*.wlt", "test/wolfram"]`; see `test/wolfram/README.md`.

## Notes

- Tests compare `dinfo`/`pdinfo` output line-for-line against the C program's files, so changing output formatting or ordering breaks them.
- `DivisorSigmaInverse.wl` ports `invsigmaDiv` from Max Alekseyev's `invphi.gp`; its structure (prime-power "building blocks" menu in `cookSigma`, then combination via `invSigmaDivisors`) follows his paper, and it uses `FunctionCompile` for the hot kernel. Recent history is performance work on it, so benchmark before and after changing it.
- Workflow is branch + PR into `main` (branches like `perf/...`, `refactor/...`, `feature/...`).
