# DivisorSigmaInverse: solving σₖ(x) = n

`src/wolfram/DivisorSigmaInverse.wl` is a Wolfram Language package (context `OEIS`) that finds every positive integer x with σₖ(x) = n, where σₖ is `DivisorSigma[k, ·]`, the sum of the k-th powers of the divisors. It is a port of `invsigmaDiv` from [`invphi.gp`](https://github.com/maxale/gpscripts/blob/main/invphi.gp) by Max Alekseyev, which follows M. A. Alekseyev, "Computing the Inverses, their Power Sums, and Extrema for Euler's Totient and Other Multiplicative Functions", J. Integer Sequences 19 (2016), Article 16.5.2.

## Loading and calling

From the repository root:

```wolfram
Get["src/wolfram/DivisorSigmaInverse.wl"];
OEIS`DivisorSigmaInverse[12]
```

```
{6, 11}
```

Both 6 (divisors 1, 2, 3, 6) and 11 (divisors 1, 11) have σ₁ = 12.

## Public functions

| Call | Returns |
|---|---|
| `DivisorSigmaInverse[n, k, u]` | The sorted list of all x ≤ u with `DivisorSigma[k, x] == n`. |
| `invSigmaDivisors[n, k, u]` | A list indexed like `Divisors[n]`: its j-th entry is the sorted list of all x ≤ u with `DivisorSigma[k, x]` equal to the j-th divisor of n. |

`n` is a positive integer. `k` is a positive integer and defaults to 1; `u` defaults to `Infinity`. `DivisorSigmaInverse[n, k, u]` is the last entry of `invSigmaDivisors[n, k, u]`.

## Examples

```wolfram
OEIS`DivisorSigmaInverse[24]          (* {14, 15, 23} *)
OEIS`DivisorSigmaInverse[31]          (* {16, 25} *)
OEIS`DivisorSigmaInverse[10]          (* {}: no x has σ(x) = 10 *)
OEIS`DivisorSigmaInverse[50, 2]       (* {6, 7}: σ₂(6) = σ₂(7) = 50 *)
OEIS`DivisorSigmaInverse[24, 1, 20]   (* {14, 15}: only solutions up to 20 *)
```

The per-divisor form, for n = 12 with `Divisors[12] = {1, 2, 3, 4, 6, 12}`:

```wolfram
OEIS`invSigmaDivisors[12]
```

```
{{1}, {}, {2}, {3}, {5}, {6, 11}}
```

So σ(x) = 1 only for x = 1, σ(x) = 2 has no solution, σ(x) = 3 for x = 2, σ(x) = 4 for x = 3, σ(x) = 6 for x = 5, and σ(x) = 12 for x = 6, 11.

## How it works

1. **Building blocks.** For each divisor d > 1 of n and each prime p dividing d − 1, a prime power p^m has σₖ(p^m) = d exactly when d (pᵏ − 1) + 1 = p^t with k | t and m = t/k − 1. The code factors d − 1 to get the candidate primes and keeps the blocks `{d, p^m}` that pass this test, grouped by prime.
2. **Dynamic programming over divisors.** σₖ is multiplicative, so any solution is a product of prime powers whose σₖ values multiply to n. The table `r[d]` holds every x built from the primes processed so far with σₖ(x) = d. For each prime, a copy `t` of `r` is updated by adding `r[m] q` to `t[m d]` for each block `{d, q}` and each m with m d dividing n. Reading from `r` and writing to `t` uses each prime at most once.
3. **Bound.** Candidates above `u` are dropped as they are produced.

## Checks

Run with local `wolframscript` (Mathematica 15.0.1, Apple silicon):

- For n = 1 to 60 and k = 1, 2, `DivisorSigmaInverse[n, k]` equals the brute-force list `Select[Range[n^(k+1) + 1], DivisorSigma[k, #] == n &]`; there were no mismatches.
- `DivisorSigmaInverse[1000]` took about 0.0002 s (no solutions), and `DivisorSigmaInverse[10!]` took about 0.02 s and returned 1195 solutions.

## Limitation

For n = 1 the bound `u` is ignored: `DivisorSigmaInverse[1, 1, 0]` returns `{1}` although 1 > 0.
