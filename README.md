# OEIS_Mathematica

[![Java tests](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/maven.yml/badge.svg?branch=main)](https://github.com/shenghuiy/OEIS_Mathematica/actions/workflows/maven.yml)

High-performance Wolfram Language code for computing a difficult OEIS sequence — too long for the OEIS program section

## Documentation

Explanations of the code in this repository are in [`docs/`](docs/README.md):

- [Carry-less (dismal) arithmetic in Java](docs/CarrylessArithmetic.md): `src/CarrylessArithmetic.java`, its methods, and how to call it from Java and from Mathematica via J/Link.
- [A399539](docs/A399539.md): `src/A399539.wl`, a compiled segmented sieve for numbers k with ψ(k) − φ(k) = d(k)⁴, with timings and the checks run in Mathematica.
- [A157196](docs/A157196.md): `src/A157196.wl`, a string construction for the self-describing sequence of 1s and 2s, with the checks run in Mathematica.

Tests for the Java code are described in [`test/README.md`](test/README.md).
