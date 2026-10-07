# Mathematical Explorations

[![Java tests](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/maven.yml/badge.svg?branch=main)](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/maven.yml)
[![Python tests](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/python.yml/badge.svg?branch=main)](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/python.yml)

A collection of research-grade tools for discrete mathematics and number theory: inverting arithmetic functions, sieving for exotic integer sequences, dissecting the dynamics of Bulgarian solitaire, and doing carry-less arithmetic. The code is written in Wolfram Language, Java and Python, checked against the literature, and explained page by page.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/img/banner-dark.png">
    <img src="docs/img/banner-light.png" alt="Mathematical Explorations: research code for OEIS sequences, with the A001333 Pell-Lucas tree" width="100%">
  </picture>
</p>

## Highlights

- **Inverting arithmetic functions.** [`DivisorSigmaInverse`](docs/DivisorSigmaInverse.md) lists every x with σₖ(x) = n, and [`EulerPhiInverse`](docs/EulerPhiInverse.md) every x with φ(x) = n. Both are compiled with `FunctionCompile`; `EulerPhiInverse` returns all 220,281 solutions for n = 2²⁰·3⁵·5²·7 in about 0.06 s.
- **Sieving for rare integers.** [A399539](docs/A399539.md) uses a compiled segmented sieve to find the numbers k with ψ(k) − φ(k) = d(k)⁴.
- **Bulgarian solitaire, end to end.** [One package](docs/BulgarianSolitaire.md) covers orbits, cycles and Brandt's necklace count, Garden of Eden partitions (OEIS [A123975](https://oeis.org/A123975)), game-tree level sizes and the row-to-column game. It reproduces the closed forms in Pham's work on limiting level-size series, and tests her conjecture on every primitive necklace of length 3 to 5.
- **Carry-less arithmetic.** [`CarrylessArithmetic`](docs/CarrylessArithmetic.md) ports David Applegate's dismal-arithmetic program to Java, matching the original C output line for line, and can be called from Mathematica through J/Link.
- **Tested.** Java and Python tests run in CI; the Wolfram packages have `VerificationTest` suites that include the examples from the docs.

## Documentation

Explanations of the code in this repository are in [`docs/`](docs/README.md).

### Functions

- [Carry-less (dismal) arithmetic in Java](docs/CarrylessArithmetic.md): `src/java/CarrylessArithmetic.java`, its methods, and how to call it from Java and from Mathematica via J/Link.
- [DivisorSigmaInverse](docs/DivisorSigmaInverse.md): `src/wolfram/DivisorSigmaInverse.wl`, a Mathematica port of `invsigmaDiv` from Max Alekseyev's `invphi.gp`; `invSigmaDivisors[n, k]` lists every x with σₖ(x) equal to each divisor of n, `DivisorSigmaInverse[n, k]` gives the solutions for n itself, and `DivisorSigmaInverseCount[n, k]` counts them.
- [Bulgarian solitaire](docs/BulgarianSolitaire.md): `src/wolfram/BulgarianSolitaire.wl`, the solitaire move on partitions with orbits, cycles and their count, Garden of Eden partitions, game-tree level sizes, and the row-to-column game.
- [EulerPhiInverse](docs/EulerPhiInverse.md): `src/wolfram/EulerPhiInverse.wl`, a compiled depth-first search for every x with φ(x) = n; `EulerPhiInverse[n]` returns them sorted.

### Wolfram Function Repository

Functions published in the Wolfram Function Repository, linked directly since they have no pages in `docs/`:

- [FoataTransform](https://resources.wolframcloud.com/FunctionRepository/resources/FoataTransform/): Foata's fundamental transformation of a permutation.
- [InverseFoataTransform](https://resources.wolframcloud.com/FunctionRepository/resources/InverseFoataTransform/): the inverse of Foata's fundamental transformation.
- [FindFanoPlaneIsomorphism](https://resources.wolframcloud.com/FunctionRepository/resources/FindFanoPlaneIsomorphism/): finds an isomorphism between Fano planes.
- [ParkingFunctionQ](https://resources.wolframcloud.com/FunctionRepository/resources/ParkingFunctionQ/): tests whether a list is a parking function.
- [ParkingFunctionToDyckWords](https://resources.wolframcloud.com/FunctionRepository/resources/ParkingFunctionToDyckWords/): converts a parking function to Dyck words.

### OEIS sequences

- [A316667](docs/A316667.md): `src/wolfram/A316667.wl`, the trapped knight walk on the square-spiral chessboard.
- [A399539](docs/A399539.md): `src/wolfram/A399539.wl`, a compiled segmented sieve for numbers k with ψ(k) − φ(k) = d(k)⁴, with timings and the checks run in Mathematica.
- [A157196](docs/A157196.md): `src/wolfram/A157196.wl`, a string construction for the self-describing sequence of 1s and 2s, with the checks run in Mathematica.
- [A003785](docs/A003785.md): `src/wolfram/A003785.wl`, a Mathematica translation of the OEIS PARI program built from eta-function products.
- [A123975](https://oeis.org/A123975): the number of Garden of Eden partitions of n in Bulgarian solitaire, computed by [`BulgarianSolitaireGardenOfEdenCount`](src/wolfram/BulgarianSolitaire.wl#L129) from the Hopkins–Sellers formula p(n−3) − p(n−9) + p(n−18) − …; see the [Bulgarian solitaire](docs/BulgarianSolitaire.md) page.

Tests for the Java code are described in [`test/java/README.md`](test/java/README.md), and tests for the Wolfram code in [`test/wolfram/README.md`](test/wolfram/README.md).

## License

[MIT](LICENSE)
