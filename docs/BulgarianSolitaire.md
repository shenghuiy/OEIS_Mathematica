# Bulgarian solitaire

`src/wolfram/BulgarianSolitaire.wl` is a Wolfram Language package (context `OEIS`) for Bulgarian solitaire on integer partitions. A move takes one card from every pile and makes a new pile of those cards. In partition terms, `B(λ) = (t, λ₁ − 1, …, λ_t − 1)` where t is the number of parts, zeros are dropped, and the result is re-sorted. The package follows five papers:

- B. Hopkins, *30 Years of Bulgarian Solitaire*, College Math. J. 43 (2012): history, the move, Garden of Eden partitions, and the row-to-column game.
- T. Hart, G. Khan, M. Khan, *Revisiting Toom's proof of Bulgarian solitaire*, Ann. Sci. Math. Québec 36 (2012): the diagonal criterion for cycles, and Brandt's necklace count.
- B. Hopkins and J. Sellers, *Exact enumeration of Garden of Eden partitions*, Integers 7(2) (2007) A19.
- H. Eriksson and M. Jonsson, *Level sizes of the Bulgarian solitaire game tree*, Fibonacci Quart. 55 (2017).
- P. Ellis, *Bulgarian Solitaire*, Westchester Area Math Circle slides (2019): the cycles for 8 and 17 cards.

Partitions are lists of positive integers in non-increasing order, so `{6, 4, 3, 1, 1}` is five piles. Arguments that are not partitions are left unevaluated.

## Loading and calling

From the repository root:

```wolfram
Get["src/wolfram/BulgarianSolitaire.wl"];
OEIS`BulgarianSolitaireStep[{6, 4, 3, 1, 1}]      (* {5, 5, 3, 2} *)
```

Nothing is compiled, so loading and the first call are instant. The computations below run in the interpreter, so run them in your own Wolfram kernel.

## Python version

`src/python/bulgarian_solitaire.py` is a standard-library port with the same functions in snake case (`step`, `orbit`, `cycle`, `distance`, `is_periodic`, `cycles`, `cycle_count`, `is_garden_of_eden`, `garden_of_eden_count`, `garden_of_eden_partitions`, `preimages`, `graph`, `levels`, `level_sizes`, `leaf_sizes`, `quasi_level_size`, `quasi_leaf_size`, `row_moves`). Partitions are tuples, and `graph` returns a dict from each partition to its image instead of a `Graph`. The tests in `test/python/test_bulgarian_solitaire.py` mirror the Wolfram ones; run them from the repository root with `python -m unittest discover -s test/python`. All 26 tests pass (Python 3, about 1 s).

## Public functions

| Call | Returns |
|---|---|
| `BulgarianSolitaireStep[p]` | The partition after one move. |
| `BulgarianSolitaireOrbit[p]` | `p`, its image, and so on, stopping just before the first partition that repeats. |
| `BulgarianSolitaireCycle[p]` | The cycle `p` ends in, starting with the first cycle partition reached. A fixed point is a cycle of length 1. |
| `BulgarianSolitaireDistance[p]` | The number of moves before `p` first reaches its cycle (0 for a cycle partition). |
| `BulgarianSolitairePeriodicQ[p]` | Whether `p` lies on a cycle, by Toom's diagonal criterion (no iteration). |
| `BulgarianSolitaireCycles[n]` | Every cycle of partitions of `n`, each rotated to start at its smallest partition. |
| `BulgarianSolitaireCycleCount[n]` | The number of cycles of partitions of `n`, from Brandt's necklace formula, without building partitions. |
| `BulgarianSolitaireGardenOfEdenQ[p]` | Whether `p` has no preimage, that is, its rank `p₁ − t` is at most −2. |
| `BulgarianSolitaireGardenOfEdenCount[n]` | The number of Garden of Eden partitions of `n`, `ge(n) = p(n−3) − p(n−9) + p(n−18) − …`. |
| `BulgarianSolitaireGardenOfEdenPartitions[n]` | The Garden of Eden partitions of `n`. |
| `BulgarianSolitairePreimages[p]` | The partitions that one move sends to `p`. |
| `BulgarianSolitaireGraph[n, opts]` | The directed graph on the partitions of `n`, edge λ → B(λ). Options go to `Graph`. |
| `BulgarianSolitaireLevels[n]` | The partitions of `n` grouped by distance to the cycles. |
| `BulgarianSolitaireLevelSizes[n]` | The size of each group. For `n = k(k+1)/2` these are the level sizes of the game tree rooted at the staircase. |
| `BulgarianSolitaireLeafSizes[n]` | The number of Garden of Eden partitions in each group, that is, the leaves on each level. |
| `BulgarianSolitaireQuasiLevelSize[d]` | The level size `F(2d)` (1 for `d = 0`) of the quasi-infinite game, `k → ∞`. |
| `BulgarianSolitaireQuasiLeafSize[d]` | The leaf count `(F(2d−2) − F(d−1))/2` of the quasi-infinite game. |
| `BulgarianSolitaireRowMoves[p]` | The partitions reached by changing any one row of the Ferrers diagram into a column. |

`n` is a positive integer.

## Examples

The 15-card game that opens Hopkins' article:

```wolfram
OEIS`BulgarianSolitaireOrbit[{6, 4, 3, 1, 1}]
```

```
{{6, 4, 3, 1, 1}, {5, 5, 3, 2}, {4, 4, 4, 2, 1}, {5, 3, 3, 3, 1},
 {5, 4, 2, 2, 2}, {5, 4, 3, 1, 1, 1}, {6, 4, 3, 2}, {5, 4, 3, 2, 1}}
```

```wolfram
OEIS`BulgarianSolitaireCycle[{6, 4, 3, 1, 1}]      (* {{5, 4, 3, 2, 1}} *)
OEIS`BulgarianSolitaireDistance[{6, 4, 3, 1, 1}]   (* 7 *)
```

Cycles. The partitions of 8 have two (Ellis, Hopkins), and 17 is the first n with three:

```wolfram
OEIS`BulgarianSolitaireCycles[8]
OEIS`BulgarianSolitaireCycleCount /@ Range[12]     (* {1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2} *)
OEIS`BulgarianSolitaireCycleCount[17]              (* 3 *)
```

Garden of Eden partitions. `(4, 4, 3, 3, 2, 2, 2)` has rank −3 and no preimage; `(6, 5)` has two preimages:

```wolfram
OEIS`BulgarianSolitaireGardenOfEdenQ[{4, 4, 3, 3, 2, 2, 2}]   (* True *)
OEIS`BulgarianSolitairePreimages[{6, 5}]                      (* {{7, 1, 1, 1, 1}, {6, 1, 1, 1, 1, 1}} *)
OEIS`BulgarianSolitaireGardenOfEdenCount[20]                  (* p(17) − p(11) + p(2) *)
```

Level sizes of the game tree for 10 cards (k = 4), the tree of Figure 2 in Eriksson and Jonsson, which has 42 vertices and height k(k − 1) = 12:

```wolfram
OEIS`BulgarianSolitaireLevelSizes[10]   (* {1, 1, 3, 5, 5, 3, 4, 4, 4, 3, 3, 3, 3} *)
OEIS`BulgarianSolitaireLeafSizes[10]    (* {0, 0, 0, 1, 3, 1, 1, 1, 2, 1, 1, 0, 3}, 14 leaves in all *)
OEIS`BulgarianSolitaireGraph[10, VertexLabels -> "Name"]
```

## How it works

1. **The move.** `Sort[Append[DeleteCases[p - 1, 0], Length[p]], Greater]`.
2. **Orbits.** The orbit is followed with an `Association` of seen partitions. The first repeat gives both the cycle and the distance (the position of the repeat).
3. **Periodic partitions.** Draw the partition as checkers on a board with row i holding the i-th part, and let `diag[k]` be the cells with `i + j − 1 = k`. A move never carries a checker from `diag[k]` to `diag[k+1]`. Write `m(m+1)/2 ≤ n < (m+1)(m+2)/2` and `r = n − m(m+1)/2`. The partitions of n on a cycle are exactly those with `k` cells on `diag[k]` for `k ≤ m`, `r` cells on `diag[m+1]`, and none beyond (Toom, Theorem 2.1). `BulgarianSolitairePeriodicQ` counts the diagonals, without iterating.
4. **Cycles.** Any choice of r of the m + 1 cells on `diag[m+1]` gives a periodic partition: row i has `m + 1 − i` cells on the smaller diagonals, plus one if its cell is chosen. `BulgarianSolitaireCycles` builds one partition per choice, iterates the move to get its cycle, rotates the cycle to start at its smallest partition, and removes duplicates. A move rotates `diag[m+1]`, so the cycles are the necklaces of m + 1 beads with r marked, and `BulgarianSolitaireCycleCount` evaluates Burnside's sum `(1/(m+1)) Σ_{d | gcd(m+1, r)} φ(d) C((m+1)/d, r/d)`. `BulgarianSolitaireCycles` visits `C(m+1, r)` choices, so use the count for large n.
5. **Garden of Eden partitions.** `(λ₁, …, λ_t)` has a preimage for each distinct part `v ≥ t − 1`: add 1 to every other part and append `v − t + 1` ones. There is none exactly when `λ₁ − t ≤ −2`. Dyson's rank generating function sums to `Σ ge(n) qⁿ = (Σ p(n) qⁿ)(Σ_{j≥1} (−1)^(j+1) q^(3j(j+1)/2))`, which is the formula `BulgarianSolitaireGardenOfEdenCount` uses.
6. **Levels.** `BulgarianSolitaireLevels[n]` groups the partitions by distance to the cycles. The periodic partitions come first; then each level is the preimages of the previous one that are not periodic. The preimage table is built once with `GroupBy[IntegerPartitions[n], step]`, so the cost is that of listing all p(n) partitions.
7. **Quasi-infinite tree.** Eriksson and Jonsson fix the level d and let k → ∞. The generating function for the level sizes of the reversed tree with its loop at the staircase is `g(x) = (1 − x)/(1 − 3x + x²)`, with `g_d = F(2d+1)`. Without the loop, the number of partitions at distance d is `F(2d)` (A088305). The leaves have `ℓ(x) = (x³ − x⁴)/((1 − x − x²)(1 − 3x + x²))`, so `ℓ_d = (F(2d−2) − F(d−1))/2` (A094292 up to an initial zero). For `n = k(k+1)/2` the actual level sizes equal `F(2d)` for `d ≤ ⌊k/2⌋` (Theorem 5.1), and level `⌊k/2⌋ + 1` is short by 1 for odd k and by `1 + k/2` for even k.
8. **Row-to-column moves.** In Hopkins' two-player game a move changes any row of the Ferrers diagram into a column. Removing row j lowers every column of height at least j by 1, and the removed cells form a new column whose height is the length of row j. Row 1 is the ordinary move. Starting from `{n}`, the first move is forced to `{n − 1, 1}`, and the second gives `{n − 2, 2}` or `{n − 2, 1, 1}`.

## Checks

The tests in `test/wolfram/BulgarianSolitaire.wlt` have not been run yet (the package was written without a Wolfram kernel), so run them locally first:

```wolfram
TestReport["test/wolfram/BulgarianSolitaire.wlt"]
```

They check:

- The examples in the papers: the 15-card orbit, the 8-card cycles, three cycles for 17 cards, the rank −3 example, Gardner's three Garden of Eden partitions for n = 6, and the preimages of `(6, 5)`.
- Igusa's partition `(k−1, k−1, k−2, …, 2, 1, 1)` being k(k−1) moves from the staircase, for k = 3 to 8.
- Toom's criterion against iterating the move, and `BulgarianSolitaireCycles` against the cycles reached from every partition of n for n ≤ 18.
- `BulgarianSolitaireCycleCount` against `Length[BulgarianSolitaireCycles[n]]` for n ≤ 40.
- `BulgarianSolitaireGardenOfEdenCount` against a direct count for n ≤ 40, and `BulgarianSolitairePreimages` against a brute-force search for n ≤ 14.
- The level sizes for 6 and 10 cards (the latter read off Figure 2 of Eriksson and Jonsson, with the 42 vertices and 14 leaves accounted for), the tree height k(k−1) for k = 2 to 7, and Theorem 5.1 for k = 3 to 8, including the deficit at level `⌊k/2⌋ + 1`.
- The generating functions for `F(2d)` and the leaf counts against the closed forms.
