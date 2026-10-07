# Tests for src/wolfram

One Wolfram test file (`.wlt`, made of `VerificationTest` cases) per package in `src/wolfram/`. Each file loads its package with a path relative to `$TestFileName`, so it runs from any working directory.

Run all of them from a Wolfram kernel (Mathematica 13.1+ for `FunctionCompile` with `DynamicArray`/`FixedArray`):

```wolfram
TestReport /@ FileNames["*.wlt", "test/wolfram"]
```

or one file (test IDs starting with `example-` are the examples from `docs/`):

```wolfram
TestReport["test/wolfram/DivisorSigmaInverse.wlt"]
```

These are not run by GitHub Actions, since the workflow has no Wolfram Engine.

| File | Cases | What is checked |
|---|---|---|
| `DivisorSigmaInverse.wlt` | 34 | The examples in the doc page, known values, the bound `u`, agreement with brute force for `k = 1, 2, 3`, the compiled DP against the interpreted fallback, and the `n >= 2^62` path. |
| `EulerPhiInverse.wlt` | 12 | Known values (including n = 1 and the no-solution cases), agreement with a table of `EulerPhi` for every n up to 4000, a case with 220,281 solutions, large even and odd n with no solution, and an n >= 2^58 that is answered by the Function Repository function. |
| `BulgarianSolitaire.wlt` | 94 | Examples from the papers (the 15-card orbit, cycles for 8 and 17 cards, Garden of Eden partitions, level sizes for 6 and 10 cards), Igusa's maximal distance, Toom's criterion and the necklace count against brute force, the Hopkins-Sellers count, and Eriksson-Jonsson Theorem 5.1 for k = 3 to 8. The HookLengths and StandardYoungTableaux examples (Function Repository, downloaded on first use). All cases pass in Mathematica 15.0.1 (the Python port's tests, with the same expected values, pass too). |
| `A399539.wlt` | 12 | The doc examples (including the 45 terms below 10^8, about 5 s), the first terms, an inclusive limit, a range spanning two sieve blocks, and a check from the definition psi - phi = d^4. |
| `A157196.wlt` | 12 | The doc examples (193 terms form `a[7]`, density of 1s), the first terms, only 1s and 2s, strings that are prefixes of each other, and the minimal level. |
| `A003785.wlt` | 9 | The 20 terms from the doc page, `etaSeries` against Euler's pentagonal theorem and the direct product, zero for `n < 3`, and regression values for the first terms. |

The `A003785` term values are regression values from the current code, not an independent source.
