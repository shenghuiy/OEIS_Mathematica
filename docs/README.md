# Documentation

Explanations of the code in this repository, one page per component.

| Page | Covers |
|---|---|
| [Carry-less (dismal) arithmetic in Java](CarrylessArithmetic.md) | `src/java/CarrylessArithmetic.java`: building it with Maven, its public methods, examples from Java and from Mathematica via J/Link, the `dinfo`/`pdinfo` columns, and performance |
| [A399539: $\psi(k) - \varphi(k) = d(k)^4$](A399539.md) | `src/wolfram/A399539.wl`: the sequence, loading and calling it, the segmented sieve behind `isokSeg`, measured performance, and the checks run in Mathematica |
| [A316667: the trapped knight](A316667.md) | `src/wolfram/A316667.wl`: the sequence, loading and calling it, how the walk is computed, and the checks run |
| [A157196: self-describing sequence of 1s and 2s](A157196.md) | `src/wolfram/A157196.wl`: the sequence, loading and calling it, the string construction behind it, and the checks run in Mathematica |
| [A101198: partitions of n with rank 1](A101198.md) | `src/wolfram/A101198.wl`: the sequence and the counts for any rank, loading and calling it, Dyson's rank generating function and Atkin and Swinnerton-Dyer's proof of it, the one-term sum and the many-term series division, timings, and the checks run in Mathematica |
| [A101199: partitions of n with rank 2](A101199.md) | `PartitionRankCount[2, n]` from `src/wolfram/A101198.wl`: the sequence, calling it, the formula for rank 2 and how its two halves count ranks at least 2 and at least 3, and the checks run |
| [A101200: partitions of n with rank 3](A101200.md) | `PartitionRankCount[3, n]` from `src/wolfram/A101198.wl`: the sequence, calling it, the formula for rank 3, and the checks run |
| [A363213: partitions of n with rank 4](A363213.md) | `PartitionRankCount[4, n]` from `src/wolfram/A101198.wl`: the sequence, calling it, the formula for rank 4, and the checks run |
| [A363214: partitions of n with rank 5](A363214.md) | `PartitionRankCount[5, n]` from `src/wolfram/A101198.wl`: the sequence, calling it, the formula for rank 5, and the checks run |
| [A064174: partitions of n with nonnegative rank](A064174.md) | `src/wolfram/A064174.wl`: the sequence, loading and calling it, its generating function summed from Dyson's, the one-term sum, Euler's recurrence split by the sign of the rank, a recurrence in the sequence itself, the asymptotic, and the checks run in Mathematica |
| [A401118: subsets of {1..n} with no LCM triangle](A401118.md) | `src/wolfram/A401118.wl`: the sequence (Erdős problem #536), loading and calling it, the compiled search with an `IncrementalFunction` subset generator, timings, and the checks run in Mathematica |
| [A401118_SCIP: A401118 by integer linear programming with SCIP](A401118_SCIP.md) | `src/wolfram/A401118_SCIP.wl` and `src/c/a401118_scip`: loading and calling it, the `"Subset"` property, the `Method` option, the LCM cliques and the integer linear program, the C wrapper and how it is loaded with `ForeignFunctionLoad`, building SCIP and the wrapper, timings against `LinearOptimization` up to n = 656, and the checks run |
| [A003785: eta-quotient sequence](A003785.md) | `src/wolfram/A003785.wl`: the translation of the OEIS PARI program, how PARI's `eta` maps to `QPochhammer`, and how to check it |
| [Bulgarian solitaire](BulgarianSolitaire.md) | `src/wolfram/BulgarianSolitaire.wl`: the move, orbits, cycles (Toom's criterion and Brandt's necklace count), Garden of Eden partitions, the level sizes of the game tree, and the row-to-column game, with the checks to run in Mathematica |
| [DivisorSigmaInverse: $\sigma_k(x) = n$](DivisorSigmaInverse.md) | `src/wolfram/DivisorSigmaInverse.wl`: finding every $x$ with $\sigma_k(x) = n$, loading and calling it, the divisor dynamic program behind it, and the checks run in Mathematica |
| [EulerPhiInverse: $\varphi(x) = n$](EulerPhiInverse.md) | `src/wolfram/EulerPhiInverse.wl`: finding every $x$ with $\varphi(x) = n$, loading and calling it, the compiled depth-first search behind it, and the checks run in Mathematica |

Related:

- [`test/README.md`](../test/README.md): the JUnit tests and the C reference outputs they compare against.
- [Repository README](../README.md)

To document another part of the repository, add a Markdown page to this folder and list it in the table above.
