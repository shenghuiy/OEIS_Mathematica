# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

Three independent code bases (Java, Wolfram Language, Python) share the repo; only the Java one has a build; the Java and Python tests run in CI.

- `src/java/CarrylessArithmetic.java` — carry-less ("dismal") arithmetic on decimal strings, a port of David Applegate's 2003 C program. Operands and results are `String`s; divisor/divide search uses a `ToIntFunction<String>` callback (a negative return stops the search). Also callable from Mathematica via J/Link.
- `src/wolfram/*.wl` — standalone Wolfram Language packages, one per OEIS sequence or topic. Each is `BeginPackage["OEIS`"]` with public symbols in the shared `OEIS`` context and helpers in `` `Private` ``, written as Mathematica notebook-style source (`(* ::Subsection:: *)` markers, so keep those cell markers intact when editing). Because every package shares `OEIS`` and `OEIS`Private``, a name leaked from one breaks the others' tests with `::shdw`; load the `wolfram-package` skill (`.claude/skills/wolfram-package`) before adding or editing a package or `.wlt` file. The partition-rank sequences (A101199, A101200, A363213, A363214) have doc pages but no package of their own: they are `PartitionRankCount[m, n]` from `A101198.wl`.
- `src/python/bulgarian_solitaire.py`, `test/python/` — a stdlib-only Python port of `BulgarianSolitaire.wl` with `unittest` tests (CI: `.github/workflows/python.yml`). `src/python/pham_conjecture.py` is a standalone script (no tests) checking a conjecture on Bulgarian solitaire level sizes; its usage is in its docstring.
- `docs/` — one Markdown explanation per source file. When changing a `.wl` or the Java class, update its doc page. A new package is listed in three indexes: `README.md` (the "ones with code here" list, which otherwise holds the user's own OEIS contributions), `docs/README.md`, and the table in `test/wolfram/README.md` (with its test count).
- `test/java/` — JUnit 5 tests; `expected/` holds reference output from the original C program, `results/` holds recorded surefire reports.
- `test/wolfram/` — one `.wlt` file (`VerificationTest` cases) per `.wl` package.

## Commands

Maven is configured with non-standard directories (`src/java`, `test/java`), Java release 11. Use plain `mvn` (as CI does). `mvn3` is only the name MacPorts gives Maven on the Mac (`/opt/local/bin/mvn3`); it does not exist on other machines, so use it only there.

```bash
mvn test                                        # all tests (CI runs this on Java 11 and 21)
mvn test -Dtest=CarrylessArithmeticTest#methodName   # single test
```

`mvn test` runs only the Java tests; the Python tests are separate (`python -m unittest discover -s test/python -v`, CI: `.github/workflows/python.yml`).

`mvn test` writes reports to `target/surefire-reports/` (gitignored). To update the recorded results, copy `CarrylessArithmeticTest.txt` and `TEST-CarrylessArithmeticTest.xml` into `test/java/results/`. See `test/java/README.md` for regenerating `expected/` from the C program.

The Wolfram tests are not part of Maven or CI. Run them in a Wolfram kernel with `TestReport /@ FileNames["*.wlt", "test/wolfram"]`; see `test/wolfram/README.md`. On the user's Mac, `wolframscript` is not on `PATH`; use `/Applications/Wolfram.app/Contents/MacOS/wolframscript -code '...'` from the repo root. In the Wolfram MCP evaluator, the `VerificationTest`s that expect messages fail (it prints messages instead of recording them), so use `wolframscript` for a real test run.

## Notes

- The Java tests compare `dinfo`/`pdinfo` output line-for-line against the C program's files, so changing output formatting or ordering breaks them.
- `DivisorSigmaInverse.wl` ports `invsigmaDiv` from Max Alekseyev's `invphi.gp`; its structure (prime-power "building blocks" menu in `cookSigma`, then combination via `invSigmaDivisors`) follows his paper, and it uses `FunctionCompile` for the hot kernel. Recent history is performance work on it, so benchmark before and after changing it.
- Workflow is branch + PR into `main` (branches like `perf/...`, `refactor/...`, `feature/...`).
