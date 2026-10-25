# A401118: subsets of {1..n} with no LCM triangle

`src/wolfram/A401118.wl` is a Wolfram Language package (context `OEIS`) for [A401118](https://oeis.org/A401118). Call three distinct numbers $i, j, k$ an *LCM triangle* when $\operatorname{lcm}(i, j) = \operatorname{lcm}(j, k) = \operatorname{lcm}(k, i)$. Then $a(n)$ is the size of the largest subset of $\{1, \dots, n\}$ that contains no LCM triangle. Erdős problem [#536](https://www.erdosproblems.com/536) asks how $a(n)$ grows.

The package solves its integer programs with `LinearOptimization`. [`A401118_SCIP.wl`](A401118_SCIP.md) adds a `Method` option and SCIP, which is about 3 times faster at $n = 300$.

## The sequence

The terms for $n = 1, 2, 3, \dots$ begin

```
1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, ...
```

For example, $a(12) = 10$. The LCM triangles in $\{1..12\}$ are $\{2,3,6\}$, $\{2,5,10\}$, $\{3,4,12\}$ and $\{4,6,12\}$. Removing 2 and 4 breaks all four. One removal is not enough, because $\{2,5,10\}$ and $\{3,4,12\}$ share no element.

## Loading and calling

From the repository root:

```wolfram
Get["src/wolfram/A401118.wl"];
OEIS`LCMTriangles[12]            (* {{2,3,6}, {2,5,10}, {3,4,12}, {4,6,12}} *)
OEIS`A401118[12]                 (* 10 *)
OEIS`A401118List[20]             (* the 20 terms above *)
OEIS`LCMTriangleFreeSubset[12]   (* a subset of size 10 with no LCM triangle *)
Length[OEIS`LCMTriangles[656]]   (* 6225 *)
```

## Public functions

| Call | Returns |
|---|---|
| `A401118[n]` | $a(n)$. |
| `A401118List[nmax]` | $\{a(1), \dots, a(n_{\max})\}$. |
| `LCMTriangles[n]` | Every LCM triangle $\{i, j, k\}$ with $i < j < k \le n$, sorted by $k$ and then $i$. |
| `LCMTriangleFreeSubset[n]` | A subset of $\{1..n\}$ of size $a(n)$ with no LCM triangle. |

The argument is a positive integer. Otherwise the function gives a `::posint` message and returns `$Failed`. Every function computes the terms from $1$ up, so `A401118[n]` costs as much as `A401118List[n]`.

## How it works

### LCM triangles from prime exponents

$i, j, k$ form an LCM triangle exactly when, for every prime $p$, the largest exponent of $p$ among the three occurs at least twice. Fix the largest element $m$ and a smaller element $i$, and let $G = \gcd(i, m)$ and $L = \operatorname{lcm}(i, m)$. A prime divides $r = L/G$ exactly when its exponents in $i$ and $m$ differ, and then the third element $k$ must carry the larger exponent. Where the exponents are equal, $k$ may carry any exponent up to that value. So $k = A d$, where $g$ is the part of $G$ coprime to $r$, $A = L/g$, and $d$ divides $g$. When $A \ge m$ there is no such $k$.

`lcmTrianglesC` is a `FunctionCompile`d loop over $m$ and $i < m$ that applies this rule using only `GCD`, `Quotient` and `Mod`, so it never factors anything. It finds the 6,225 triangles up to 656 in 0.01 s, and the 37,049 up to 2000 in 0.12 s. Testing all $\binom{n}{3}$ triples instead takes 3 s just to reach 656.

### One term at a time

The OEIS entry notes that $a(m-1) \le a(m) \le a(m-1) + 1$. So each new term asks one question: is there a triangle-free subset of $\{1..m\}$ with $a(m-1) + 1$ elements? Such a subset must contain $m$, and the only new triangles are those whose largest element is $m$. The package keeps a witness $S$ for $a(m-1)$ and proceeds as follows:

1. If no new triangle has both of its smaller elements in $S$, then $S \cup \{m\}$ is triangle-free and $a(m) = a(m-1) + 1$, with no solve. This covers every $m$ that lies in no triangle, such as 1 and the primes, and most other terms too.
2. Otherwise `LinearOptimization` maximizes $\sum x_v$ over 0-1 variables $x_v$. Only numbers that lie in some triangle get a variable, since the others can always be added. If the maximum, plus the number of numbers in no triangle, reaches $a(m-1) + 1$, the solution becomes the new witness. Otherwise $a(m) = a(m-1)$ and $S$ is kept.

Up to $n = 200$, 72 of the 200 terms needed a solve. The solves that found no larger set, where the term stays at $a(m-1)$, took 43.3 s of the 43.7 s spent solving.

The solver is a function `solve[vars, cliques]` that returns the elements of `vars` kept in an optimal solution. `a401118Run` takes it as an argument, and calls without options get it from the private `a401118DefaultSolver`. That is the hook `A401118_SCIP.wl` uses.

### Clique constraints

All three pairs of a triangle have the same LCM $L$. Fix $L$ and join two numbers when their LCM is $L$. In a clique of that graph, every three elements form a triangle, so at most two of them can be kept. The package therefore uses one constraint $\sum x \le 2$ per maximal clique (`FindClique`) instead of one per triangle. An example is $\{6, 10, 15, 30\}$, whose pairwise LCMs are all 30. At each step, only the cliques of LCMs that gained a triangle are recomputed. For $m = 198$ (173 variables), the 857 triangles become 721 cliques, 51 of them of size 4.

Timings for that problem with `LinearOptimization`, where 145 elements turn out to be impossible:

| Formulation | Time |
|---|---|
| Feasibility ($\sum x \ge$ target), one constraint per triangle | 7.6 s |
| Feasibility, one constraint per clique | 4.6 s |
| Maximize $\sum x$, one constraint per clique (used) | 3.7 s |

Two ideas did not help and are not used:

- **Prefix cuts:** $\sum_{v \le m'} x_v \le a(m')$ for the known earlier terms. These are valid, but they made each solve 2 to 3 times slower.
- **Merging large primes:** primes $p > \sqrt m$ with the same $\lfloor m/p \rfloor$ have isomorphic sets of multiples, so one representative with a weight could stand in for all of them. The optimum is the same, but the time stayed at 3.7 s.

## Performance

Measured with Mathematica 15.0.1 on Windows, using the built-in integer solver. Gurobi, CPLEX, Xpress and MOSEK are not installed there. Each run starts from $n = 1$ and was checked against the b-file.

| | Time |
|---|---|
| Loading the package (compiling `lcmTrianglesC`) | about 38 s |
| `A401118List[150]` | 7.0 s |
| `A401118List[200]` | 56.0 s |
| `A401118List[300]` | 266.7 s |

The time grows quickly with $n$, since the integer programs that prove no larger set exists get harder. The entry's 656 terms were computed with SCIP and HiGHS. This package has been checked against them up to $n = 300$; see [A401118_SCIP](A401118_SCIP.md) for the SCIP timings.

## Checks run

Run `test/wolfram/A401118.wlt` (18 cases, about 1 minute, most of it the compile at load). It checks:

- The examples above and the OEIS DATA section.
- The b-file up to $n = 150$.
- `LCMTriangles[80]` against testing every triple.
- $a(n)$ against brute force over all subsets of $\{1..14\}$.
- That `LCMTriangleFreeSubset[120]` is triangle-free with 88 elements.
- The entry's formulas up to 150: $a(n+1) - a(n) \in \{0, 1\}$, $a(p) = a(p-1) + 1$ for primes $p$, and $a(n) \le n - \lfloor n/6 \rfloor$.
- That loading the package sets `LinearOptimization` as the default solver.
- That only the four public names are in `` OEIS` ``.
- The messages for invalid arguments.

Separately, `A401118List[300]` was checked against the b-file.

## References

- [A401118](https://oeis.org/A401118), the OEIS entry, with the b-file of 656 terms.
- [Erdős problem #536](https://www.erdosproblems.com/536), T. F. Bloom.
- H. L. Abbott and B. Gardner, the lower bound $a(n) \ge (1 - o(1))\, n \log\log n / \log n$ (1967), as cited in the OEIS entry.
