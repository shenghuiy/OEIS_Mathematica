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
| `BulgarianSolitaire.wlt` | 107 | Examples from the papers (the 15-card orbit, cycles for 8 and 17 cards, Garden of Eden partitions, level sizes for 6 and 10 cards), Igusa's maximal distance, Toom's criterion and the necklace count against brute force, the Hopkins-Sellers count, and Eriksson-Jonsson Theorem 5.1 for k = 3 to 8. The HookLengths and StandardYoungTableaux examples (Function Repository, downloaded on first use). All cases pass in Mathematica 15.0.1 (the Python port's tests, with the same expected values, pass too). |
| `A399539.wlt` | 13 | The doc examples (including the 45 terms below $10^8$, about 5 s), the first terms, an inclusive limit, a range spanning two sieve blocks, a check from the definition $\psi - \varphi = d^4$, and that the helper `isokSeg` and the variable `n` stay out of the public `` OEIS` `` context. |
| `A157196.wlt` | 12 | The doc examples (193 terms form `a[7]`, density of 1s), the first terms, only 1s and 2s, strings that are prefixes of each other, and the minimal level. |
| `A101198.wlt` | 34 | The doc examples (including those on the A101199, A101200, A363213 and A363214 pages), the OEIS DATA sections for ranks 0 to 5 (A047993, A101198, A101199, A101200, A363213, A363214), b-file values of A101198 up to n = 2000 from both the list and the single-term function, both single-term methods on either side of the n = 1000 cutoff, brute force with `IntegerPartitions` for \|m\| <= 6 and n <= 24, the list form against single terms, the counts over all ranks adding up to p(n), the extreme ranks, the Hopkins-Sellers sum for rank >= 2 and its analogues for rank >= 3 to 6, and the messages for invalid arguments. About 0.2 s. |
| `A064174.wlt` | 24 | The doc examples, the OEIS DATA section and b-file values up to n = 10000 from both the list and the single-term function, brute force with `IntegerPartitions` for n <= 30 by the definition and both OEIS descriptions, the recurrence against the single-term sums, the complement A064173 and the rank-0 count A047993, two generating functions, the asymptotic constant, and the messages for invalid arguments. About 1.6 s. |
| `A401118.wlt` | 10 | The doc examples ($a(6) = 5$, $a(12) = 10$ and the LCM triangles behind them), the first 24 terms of the OEIS DATA section, the uncompiled definition for n <= 16, the `IncrementalObject["Subsets"]` search against the compiled one for n <= 20, the order of the compiled k-subset generator, and that only `A401118` is public. Needs Mathematica 15.0 (`IncrementalFunction`). About 40 s, mostly the compile. |
| `A401118_SCIP.wlt` | 19 | That `A401118SCIP` is the only public name and has `Method -> Automatic`, the doc examples, the first 19 DATA terms with each method, the `"Size"` and `"Subset"` properties, that the LCM cliques have equal pairwise LCMs and cover every LCM triangle up to 40 (brute force), a triangle-free `"Subset"` for n = 12 and, with each method, n = 19, that `Automatic` picks SCIP exactly when its library in `build/` is found and falls back without it, with SCIP the whole DATA section, b-file values at 100, 150, 200 and a triangle-free `"Subset"` for n = 150, and the messages. Cases that can run `LinearOptimization` keep n < 20. About 5 s. |
| `A003785.wlt` | 9 | The 20 terms from the doc page, `etaSeries` against Euler's pentagonal theorem and the direct product, zero for `n < 3`, and regression values for the first terms. |

The `A003785` term values are regression values from the current code, not an independent source.
