# Documentation

Explanations of the code in this repository, one page per component.

| Page | Covers |
|---|---|
| [Carry-less (dismal) arithmetic in Java](CarrylessArithmetic.md) | `src/java/CarrylessArithmetic.java`: building it with Maven, its public methods, examples from Java and from Mathematica via J/Link, the `dinfo`/`pdinfo` columns, and performance |
| [A399539: ψ(k) − φ(k) = d(k)⁴](A399539.md) | `src/wolfram/A399539.wl`: the sequence, loading and calling it, the segmented sieve behind `isokSeg`, measured performance, and the checks run in Mathematica |
| [A316667: the trapped knight](A316667.md) | `src/wolfram/A316667.wl`: the sequence, loading and calling it, how the walk is computed, and the checks run |
| [A157196: self-describing sequence of 1s and 2s](A157196.md) | `src/wolfram/A157196.wl`: the sequence, loading and calling it, the string construction behind it, and the checks run in Mathematica |
| [A003785: eta-quotient sequence](A003785.md) | `src/wolfram/A003785.wl`: the translation of the OEIS PARI program, how PARI's `eta` maps to `QPochhammer`, and how to check it |
| [Bulgarian solitaire](BulgarianSolitaire.md) | `src/wolfram/BulgarianSolitaire.wl`: the move, orbits, cycles (Toom's criterion and Brandt's necklace count), Garden of Eden partitions, the level sizes of the game tree, and the row-to-column game, with the checks to run in Mathematica |
| [DivisorSigmaInverse: σₖ(x) = n](DivisorSigmaInverse.md) | `src/wolfram/DivisorSigmaInverse.wl`: finding every x with σₖ(x) = n, loading and calling it, the divisor dynamic program behind it, and the checks run in Mathematica |
| [EulerPhiInverse: φ(x) = n](EulerPhiInverse.md) | `src/wolfram/EulerPhiInverse.wl`: finding every x with φ(x) = n, loading and calling it, the compiled depth-first search behind it, and the checks run in Mathematica |

Related:

- [`test/README.md`](../test/README.md): the JUnit tests and the C reference outputs they compare against.
- [Repository README](../README.md)

To document another part of the repository, add a Markdown page to this folder and list it in the table above.
