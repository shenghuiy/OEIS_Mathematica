# Tests for CarrylessArithmetic.java

JUnit 5 tests, run with Maven from the repository root:

```bash
mvn test
```

GitHub Actions (`.github/workflows/maven.yml`) runs the same `mvn test` on Java 11 and 21 for every pull request and every push to `main`, and keeps the surefire reports as a downloadable artifact of each run.

## Layout

| Path | Contents |
|---|---|
| `CarrylessArithmeticTest.java` | The tests (39 cases). |
| `expected/` | Reference output from the original C program (David Applegate, 2003) for the same inputs. |
| `results/` | Surefire reports from the last recorded run: `CarrylessArithmeticTest.txt` (summary) and `TEST-CarrylessArithmeticTest.xml` (one entry per test case, with its time). |

A fresh `mvn test` writes its reports to `target/surefire-reports/`. To update the recorded results, copy those two files into `results/`.

## What is tested

- `dismalAdd`, `dismalMul` and `incrDigitNum` on values checked against the C program.
- `dismalDivisors` and `dismalDivide` give the C program's results in the same order. Every quotient multiplies back to the dividend, divisions with no solution report none, and a negative callback result stops the search after one result.
- `dinfo` and `pdinfo` tables are line-for-line identical to the C program's `dinfo` / `pdinfo` output.
- `pCountRange` matches the C program's `pcount`. `pPrimesRange` starts like OEIS A087097, is increasing, has the same length as `pCountRange`, and every prime contains a 9.
- Empty ranges (`lo > hi`) give empty results.

## Regenerating `expected/`

Compile the original C program (`cc -o dismal dismal.c`) and run, for example:

```bash
./dismal divs 1234        > expected/divs_1234.txt
./dismal div 11111 11     > expected/div_11111_11.txt
./dismal dinfo 1 300      > expected/dinfo_1_300.txt
./dismal pdinfo 1 2000    > expected/pdinfo_1_2000.txt
```

Each file name gives the command and arguments that produced it.
