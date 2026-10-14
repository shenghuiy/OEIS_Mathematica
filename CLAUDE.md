# CLAUDE.md

## Layout

Independent code bases share the repo: Java (the only one with a build), Wolfram Language packages, and a stdlib-only Python port.

- `src/java/CarrylessArithmetic.java`: carry-less ("dismal") arithmetic on decimal strings, a port of David Applegate's 2003 C program. Operands and results are `String`s; divisor/divide search uses a `ToIntFunction<String>` callback (a negative return stops the search). Also callable from Mathematica via J/Link.
- `src/wolfram/*.wl`: one package per OEIS sequence or topic. Each is `BeginPackage["OEIS`"]` with public symbols in the shared `OEIS`` context and helpers in `` `Private` ``, written as Mathematica notebook-style source (`(* ::Subsection:: *)` markers, so keep those cell markers intact when editing).
- `src/python/`: ports of Wolfram packages; `test/python/` holds their `unittest` tests.
- `docs/`: one Markdown page per source file, indexed from `README.md`. Update the page when changing its `.wl` or the Java class.
- `test/wolfram/`: one `.wlt` per `.wl`; not part of Maven or CI. How to run: `test/wolfram/README.md`.
- `test/java/`: `expected/` is reference output from the original C program (regenerate per `test/java/README.md`); `results/` is recorded surefire output.

## Commands

Use plain `mvn` (as CI does). `mvn3` is MacPorts' name for Maven on the Mac only. `mvn test` runs only the Java tests; Python has its own runner (see `.github/workflows/python.yml`).

To update the recorded results after `mvn test`, copy `CarrylessArithmeticTest.txt` and `TEST-CarrylessArithmeticTest.xml` from `target/surefire-reports/` into `test/java/results/`.

## Notes

- Java tests compare `dinfo`/`pdinfo` output line-for-line against the C program's files, so changing output formatting or ordering breaks them.
- `DivisorSigmaInverse.wl` ports `invsigmaDiv` from Max Alekseyev's `invphi.gp`; its structure (prime-power "building blocks" menu in `cookSigma`, then combination via `invSigmaDivisors`) follows his paper, and it uses `FunctionCompile` for the hot kernel. Recent history is performance work on it, so benchmark before and after changing it.
- Workflow is branch + PR into `main` (branches like `perf/...`, `refactor/...`, `feature/...`).
