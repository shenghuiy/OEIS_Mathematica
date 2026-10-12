# EulerPhiInverse: solving $\varphi(x) = n$

`src/wolfram/EulerPhiInverse.wl` is a Wolfram Language package (context `OEIS`) that finds every positive integer $x$ with $\varphi(x) = n$, where $\varphi$ is `EulerPhi`. The search is compiled with `FunctionCompile`.

## Loading and calling

From the repository root:

```wolfram
Get["src/wolfram/EulerPhiInverse.wl"];
OEIS`EulerPhiInverse[24]
```

```
{35, 39, 45, 52, 56, 70, 72, 78, 84, 90}
```

Loading is instant. The compiled kernel is built the first time it is needed, which takes about 20 s once per session.

## Public function

| Call | Returns |
|---|---|
| `EulerPhiInverse[n]` | The sorted list of all $x$ with `EulerPhi[x] == n`. |

`n` is a positive integer.

## Examples

```wolfram
OEIS`EulerPhiInverse[1]    (* {1, 2} *)
OEIS`EulerPhiInverse[12]   (* {13, 21, 26, 28, 36, 42} *)
OEIS`EulerPhiInverse[14]   (* {}: no x has φ(x) = 14 *)
OEIS`EulerPhiInverse[3]    (* {}: φ(x) is even for x > 2 *)
```

## How it works

1. **Candidate primes.** If $p^e$ divides $x$, then $\varphi(p^e) = p^{e-1} (p - 1)$ divides $\varphi(x) = n$, so $p - 1$ divides $n$. The compiled kernel takes the divisors $d$ of $n$ with $d + 1$ prime, giving the primes $p = d + 1$.
2. **Depth-first search.** Starting from the largest candidate prime, the search keeps the remaining target `x` (initially n) and the product `y` built so far. For a prime $p$ with $p - 1$ dividing `x`, it divides `x` by $p - 1$, then for $e = 1, 2, \dots$ multiplies `y` by $p$ and recurses on the quotient by $p^{e-1}$, using only smaller primes, for as long as $p^{e-1}$ still divides the remaining quotient. When the remaining target reaches 1, `y` is a solution. A recursive call is made only when the quotient can still be completed: a quotient of 1 is recorded on the spot (together with 2y when the prime 2 is still unused, since $\varphi(2) = 1$), while an odd quotient above 1, or any quotient once no smaller primes are left, is a dead end and is skipped. This removes about 85% of the nodes visited.
3. **One pass.** Solutions are appended to a growable `DynamicArray`, so a single search finds all of them. The array starts with a 0, because compiled code cannot return an empty array; `EulerPhiInverse` drops it and sorts the rest.
4. **Integer width.** The kernel uses `Integer64`, which is safe for $n < 2^{58}$: every solution is then below $7.5n < 2^{63}$ and every intermediate product is at most $2n$. The kernel is compiled on first use. For $n \ge 2^{58}$, `EulerPhiInverse` hands the problem to the Function Repository's [EulerPhiInverse](https://resources.wolframcloud.com/FunctionRepository/resources/EulerPhiInverse/) (a compiled `Integer128` version crashed the kernel once its result array grew past a few dozen elements, Mathematica 15.0.1 on Windows).

Odd $n$ are answered without compiling anything: $\varphi(x)$ is even for $x > 2$, so only $n = 1$ has solutions, namely `{1, 2}`.

## Checks

Run with local `wolframscript` (Mathematica 15.0.1, Apple silicon):

- For every $n$ from 1 to 4000, `EulerPhiInverse[n]` equals the list of x with `EulerPhi[x] == n` taken from a table of `EulerPhi[Range[120000]]`; there were no mismatches.
- A case with $n \ge 2^{58}$ (built from $\varphi(2^{61} \cdot 3^2 \cdot 5)$, answered by the Function Repository function) returns a sorted list containing that $x$ with every entry satisfying $\varphi(x) = n$.
- Timings per call (after the kernel is compiled):

| $n$ | solutions | time |
|---|---|---|
| $2^{20} 3^5 5^2 7$ | 220,281 | 0.059 s |
| $2^{10} 3^4 5^2 \cdot 7 \cdot 11 \cdot 13$ | 99,969 | 0.035 s |
| $2^{40} 3^{10}$ | 327,601 | 0.094 s |
| 720720 | 308 | 0.20 ms |
