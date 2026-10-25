# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

Independent code bases share the repo: Java (the only one built in CI), Wolfram Language packages, a stdlib-only Python port, and one C wrapper for a Wolfram package. The Java and Python tests run in CI.

- `src/java/CarrylessArithmetic.java`: carry-less ("dismal") arithmetic on decimal strings, a port of David Applegate's 2003 C program. Operands and results are `String`s; divisor/divide search uses a `ToIntFunction<String>` callback (a negative return stops the search). Also callable from Mathematica via J/Link.
- `src/wolfram/*.wl`: one package per OEIS sequence or topic. Each is `BeginPackage["OEIS`"]` with public symbols in the shared `OEIS`` context and helpers in `` `Private` ``, written as Mathematica notebook-style source (`(* ::Subsection:: *)` markers, so keep those cell markers intact when editing). Every package shares `OEIS`` and `OEIS`Private``, so a name leaked from one breaks the others' tests with `::shdw`; load the `wolfram-package` skill (`.claude/skills/wolfram-package`) before adding or editing a package or `.wlt` file, or running Wolfram code (it says when the Wolfram Cloud may stand in for a local kernel). The partition-rank sequences (A101199, A101200, A363213, A363214) have doc pages but no package: they are `PartitionRankCount[m, n]` from `A101198.wl`. `A064174.wl` (nonnegative rank) is a separate package.
- `src/c/a401118_scip/`: a C wrapper around SCIP's API for `A401118_SCIP.wl` (A401118 as an integer linear program, `Method -> "SCIP"`), loaded with `ForeignFunctionLoad`. SCIP and SoPlex are shallow git submodules at the root (`scip/`, `soplex/`, release tags); the build (steps in `docs/A401118_SCIP.md`) goes to `build/` and puts the wrapper and its DLLs in `lib/`, both gitignored. Not built in CI.
- `src/python/`: `bulgarian_solitaire.py` ports `BulgarianSolitaire.wl`, with `unittest` tests in `test/python/`; `pham_conjecture.py` is a standalone script (no tests), usage in its docstring.
- `docs/`: one Markdown page per source file. Update the page when changing its `.wl` or the Java class. Pages are read on GitHub, whose math rendering drops some TeX backslashes; load the `docs-page` skill (`.claude/skills/docs-page`) before writing or editing math in any `.md`. A new package goes in three indexes: `README.md` (the "ones with code here" list; the rest of that file is the user's own OEIS contributions), `docs/README.md`, and the table in `test/wolfram/README.md` (with its test count).
- `test/wolfram/`: one `.wlt` (`VerificationTest` cases) per `.wl`.
- `test/java/`: JUnit 5 tests. `expected/` is reference output from the original C program (regenerate per `test/java/README.md`); `results/` is recorded surefire output.

## Commands

Use plain `mvn` (as CI does). `mvn3` is MacPorts' name for Maven on the Mac only (`/opt/local/bin/mvn3`).

```bash
mvn test                                             # Java tests (CI: Java 11 and 21)
mvn test -Dtest=CarrylessArithmeticTest#methodName   # single test
python -m unittest discover -s test/python -v        # Python tests (CI: .github/workflows/python.yml)
```

On the user's Windows machine, `python` on `PATH` is the Microsoft Store stub ("Python was not found"); use Python 3.14, `C:\Users\sheng\AppData\Local\Programs\Python\Python314\python.exe` (or `py`, whose default is 3.14). Maven 3.9.16 is at `D:\apache-maven-3.9.16` (its `bin` is on the user `PATH`), running on Java 11.

`.claude/settings.json` has a PostToolUse hook (`.claude/hooks/mvn-test-on-java-edit.js`) that runs `mvn -q test` after any edit under `src/java/` and feeds failures back; it skips with a message when no Maven is found on `PATH`.

To update the recorded results after `mvn test`, copy `CarrylessArithmeticTest.txt` and `TEST-CarrylessArithmeticTest.xml` from `target/surefire-reports/` into `test/java/results/`.

The Wolfram tests are not part of Maven or CI: run `TestReport /@ FileNames["*.wlt", "test/wolfram"]` in a kernel (see `test/wolfram/README.md`). On the user's Mac, `wolframscript` is not on `PATH`; use `/Applications/Wolfram.app/Contents/MacOS/wolframscript -code '...'` from the repo root. On Windows, `wolframscript` is on `PATH`. The Wolfram MCP evaluator prints messages instead of recording them, so tests that expect messages fail there; the MCP `TestReport` tool does record them and runs the whole directory in a fresh kernel (about 2–3 min). Its output for the full suite is too large to return, so grep the saved file for `# Test Results Summary`. If it cannot start a fresh kernel (license limit), `newKernel: false` reuses the running one, where a `Global`` symbol left from earlier evaluations can cause a spurious `::shdw`.

## Notes

- Java tests compare `dinfo`/`pdinfo` output line-for-line against the C program's files, so changing output formatting or ordering breaks them.
- `DivisorSigmaInverse.wl` ports `invsigmaDiv` from Max Alekseyev's `invphi.gp`; its structure (prime-power "building blocks" menu in `cookSigma`, then combination via `invSigmaDivisors`) follows his paper, and it uses `FunctionCompile` for the hot kernel. Recent history is performance work on it, so benchmark before and after changing it.
- Workflow is branch + PR into `main` (branches like `perf/...`, `refactor/...`, `feature/...`). A PR may already be merged by the time a follow-up is ready, so before pushing a follow-up commit check `gh pr view <n> --json state`; once it is `MERGED`, a push to its branch reaches nothing, so branch again from `origin/main` and open a new PR.
