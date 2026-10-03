# Documentation

Explanations of the code in this repository, one page per component.

| Page | Covers |
|---|---|
| [Carry-less (dismal) arithmetic in Java](CarrylessArithmetic.md) | `src/CarrylessArithmetic.java`: building it with Maven, its public methods, examples from Java and from Mathematica via J/Link, the `dinfo`/`pdinfo` columns, and performance |
| [A399539: ψ(k) − φ(k) = d(k)⁴](A399539.md) | `src/A399539.wl`: the sequence, loading and calling it, the segmented sieve behind `isokSeg`, measured performance, and the checks run in Mathematica |

Related:

- [`test/README.md`](../test/README.md): the JUnit tests and the C reference outputs they compare against.
- [Repository README](../README.md)

To document another part of the repository, add a Markdown page to this folder and list it in the table above.
