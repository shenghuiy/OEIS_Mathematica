# EulerPhiInverse: solving φ(x) = n

`src/wolfram/EulerPhiInverse.wl` is a Wolfram Language package (context `OEIS`) that finds every positive integer x with φ(x) = n, where φ is `EulerPhi`. The search is compiled with `FunctionCompile`, using 128-bit integers.

## Loading and calling

From the repository root:

```wolfram
Get["src/wolfram/EulerPhiInverse.wl"];
OEIS`EulerPhiInverse[24]
```

```
{35, 39, 45, 52, 56, 70, 72, 78, 84, 90}
```

Loading compiles the kernels and takes about 40 s.

## Public function

| Call | Returns |
|---|---|
| `EulerPhiInverse[n]` | The sorted list of all x with `EulerPhi[x] == n`. |

`n` is a positive integer.

## Examples

```wolfram
OEIS`EulerPhiInverse[1]    (* {1, 2} *)
OEIS`EulerPhiInverse[12]   (* {13, 21, 26, 28, 36, 42} *)
OEIS`EulerPhiInverse[14]   (* {}: no x has φ(x) = 14 *)
OEIS`EulerPhiInverse[3]    (* {}: φ(x) is even for x > 2 *)
```

## How it works

1. **Candidate primes.** If p^e divides x, then φ(p^e) = p^(e−1) (p − 1) divides φ(x) = n, so p − 1 divides n. The compiled kernel `cf2` takes the divisors d of n with d + 1 prime, giving the primes p = d + 1.
2. **Depth-first search.** Starting from the largest candidate prime, the search keeps the remaining target `x` (initially n) and the product `y` built so far. For a prime p with p − 1 dividing x, it divides x by p − 1, then for e = 1, 2, … multiplies y by p and recurses on the quotient by p^(e−1), using only smaller primes, for as long as p^(e−1) still divides the remaining quotient. When the remaining target reaches 1, `y` is a solution.
3. **Storage.** Solutions go into a preallocated `FixedArray` of `Integer128` values, and the kernel stops once `bound` of them are stored. It returns the array and the count.
4. **Reading the result.** `cfExtract` takes that array and the count and returns the stored values as a list.
5. **The bound.** A count equal to `bound` may mean the search was cut off, so `EulerPhiInverse` starts at 1024 and doubles the bound until the count is strictly smaller, then sorts the values from `cfExtract`.

Two special cases are handled outside the kernel. `cf2` returns nothing for odd n, but φ(1) = φ(2) = 1, so `EulerPhiInverse[1]` returns `{1, 2}` directly. `cfExtract` returns `{0}` for a zero count, which `EulerPhiInverse` turns into `{}`.

## Checks

Run with local `wolframscript` (Mathematica 15.0.1, Apple silicon):

- For every n from 1 to 4000, `EulerPhiInverse[n]` equals the list of x with `EulerPhi[x] == n` taken from a table of `EulerPhi[Range[120000]]`; there were no mismatches.
- `EulerPhiInverse[2^20 3^5 5^2 7]` returned 220,281 solutions in about 0.33 s, sorted, each with φ(x) = n. This needs several doublings of the bound.
