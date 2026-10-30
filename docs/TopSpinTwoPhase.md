# TopSpin two-phase solver

[`src/c/topspin_twophase/topspin_twophase.c`](../src/c/topspin_twophase/topspin_twophase.c) is a C implementation of Kociemba's two-phase method for the 20-token TopSpin puzzle of [`TopSpin.wl`](TopSpin.md), and `TopSpinSolve[state, Method -> "TwoPhase"]` calls it through `ForeignFunctionLoad`. It counts compressed steps, as `TopSpinSolve[state, "CompressRotations" -> True]` does: a run of rotations is one step and each flip is one step. Over the 200 benchmark positions it averages 43 to 51 steps, depending on how long it searches, against 123.6 for the stored table. It needs about 1.7 GB of tables, which take about 2 minutes to build the first time and about 4 s after that.

## Results

The 200 positions are `SeedRandom[1]; Table[RandomSample[Range[20]], {200}]`, as on the [TopSpin](TopSpin.md#performance) page. The two-phase times are on 16 threads (Windows, MSVC 19.44), not counting the tables. Every solution was replayed to the solved state. Two variants means the position and its relabeled form (below), which is what `TopSpinSolve` searches.

| Solver | Steps, average | Steps, longest | Elementary moves, average | Elementary moves, longest | Flips, average | Time per solve |
|---|---|---|---|---|---|---|
| `TopSpinSolve` (stored table) | 123.6 | 185 | 179.9 | 261 | 61.4 | 0.46 ms |
| Two-phase, first solution | 51.0 | 59 | 97.5 | 120 | 25.4 | 4.5 ms (longest 54 ms) |
| Two-phase, first solution, two variants | 49.9 | 60 | 95.9 | 120 | 24.7 | 3.4 ms (longest 59 ms) |
| Two-phase, one phase-1 length | 49.1 | 59 | 94.1 | 115 | 24.4 | 28 ms (longest 0.31 s) |
| Two-phase, one phase-1 length, two variants (`Method -> "TwoPhase"`) | 48.5 | 60 | 93.6 | 120 | 24.0 | 24 ms (longest 0.74 s) |
| Two-phase, two phase-1 lengths | 47.8 | 57 | 91.8 | 115 | 23.8 | 76 ms (longest 1.2 s) |
| Two-phase, 0.1 s, two variants | 45.2 | 54 | 87.2 | 102 | 22.4 | 0.1 s |
| Two-phase, 1 s | 44.1 | 53 | 85.4 | 105 | 21.9 | 1 s |
| Two-phase, 1 s, two variants | 43.1 | 51 | 84.1 | 103 | 21.3 | 1 s |

The elementary moves are those of the same solutions with each step `Rk` or `Lk` written out, for comparison with `TopSpinSolve`'s default output. The search minimizes steps and, among solutions with the fewest steps, elementary moves. The rows by phase-1 length give the same moves on any number of threads; the rows by time do not. Through `TopSpinSolve` in Mathematica 15.0.1, `Method -> "TwoPhase"` took 24 ms per position and `{"TwoPhase", "PhaseOneLengths" -> 2}` 60 ms (47.0 steps, longest 57).

On the first 20 positions, where `TopSpinSolve` averages 120.1 steps, two variants give 43.2 steps (longest 46) in 1 s and 41.8 steps (longest 45, 81.8 elementary moves) in 10 s.

Counting words gives a lower bound of about 27 to 29 steps (14 flips) for a typical position, so the shortest solutions lie somewhere between that and about 42 steps.

Positions next to the solved one are not all easy. Swapping two adjacent tokens takes 40 steps (the stored table needs 65), in 4 to 8 s, because phase 1 has to undo the parity described below.

## How it works

### Phase 2: the subgroup H

Phase 2 uses only the even rotations $R^2, R^4, \dots, R^{18}$ and the flip $F$. They generate a subgroup $H$ of order $2 \cdot 10! = 7{,}257{,}600$. Under these moves the tokens travel as 10 rigid pairs in the slots of positions 1–2, 3–4, …, 19–20, and the orientation of each pair is fixed by where the pairs are, up to one bit for all of them together. A breadth-first search stores the distance of every element of $H$ in steps, and the fewest elementary moves among the shortest words. Distances in $H$ average 23.7 steps and reach 42.

### Phase 1: cosets of H

Phase 1 brings the position into $H$, or into $HR$, from which one odd rotation enters $H$. What phase 1 has to fix is the coset of $H$ the position lies in. There are $20!/(2 \cdot 10!) \approx 3.35 \times 10^{11}$ cosets, too many for a table. A coset is described by two pieces:

- the matching: which pairs of positions hold the two tokens of a label pair (1 and 2, 3 and 4, …), one of 654,729,075 perfect matchings of 20 positions;
- the coloring: each token gets a color from its label, a 4-periodic pattern (1 and 4 one color, 2 and 3 the other, and so on), so the two tokens of a pair get different colors. The colors of the 20 positions are taken up to swapping the two colors.

The goal is the matching of adjacent slots (or of adjacent positions shifted by one, for $HR$) with the coloring that alternates in blocks of two.

A phase-1 word alternates a rotation and $F$ and ends with $F$. Phase 1 searches these words by IDA*, with three lower bounds:

- **Coloring.** The exact distance of the coloring alone, from a table of all $2^{20}$ masks (184,756 are colorings). It is at most 19 steps.
- **Matching and parity.** The exact distance of the matching together with one bit, the parity: the number of label pairs whose higher label is in the lower of their two positions, taken mod 2. That makes 2 × 654,729,075 states, at most 36 steps away and about 23.7 on average. They are stored at 4 bits each (655 MB), with the 4,010 entries above 30 steps in a separate list.
- **Near the goal.** The exact distance of every coset within 16 steps of the goal: 45,780,118 cosets, in a hash table of $2^{27}$ entries. A coset that is not in it is at least 18 steps away.

Phase 1 is deep: about 30 steps for a random position, against about 18 from counting words. Most of the search happens just above the 16-step region, where the bound changes from the tables to exact distances. Without that region, the first solution of a position took about 26 s instead of about 0.15 s.

The parity bit is there for positions like a single transposition. Swapping the two tokens of one pair leaves every pair in its slot, so the matching alone is already the goal's, and every other table also puts the coset close to the goal. Phase 1 nevertheless needs 36 steps, and with the matching alone the search had found nothing after 32 steps and 2 minutes. With the parity, that coset is 36 steps away, the farthest of all, which is exact. The parity also made random positions about 2.7 times faster.

### The search

As in Kociemba's solver, the search does not stop at the shortest phase 1. For each phase-1 length, from the lower bound upward, it finds every phase-1 solution of exactly that length and completes it with a phase-2 lookup. It moves on to longer phase 1 until the time runs out or the phase-1 length reaches the best total. Longer phase-1 solutions are much more numerous: the first benchmark position has 127,258 of length 30 and about 8.6 million of length 32, and the best total fell from 51 to 47 as the search reached length 33. A search that ran to the end would give a shortest solution, but the number of phase-1 solutions grows by about 15 times per two steps.

The subtrees near the root are searched in parallel (OpenMP). Each subtree keeps its own best solution, and the bests are merged in a fixed order. In the reproducible mode, which `Method -> "TwoPhase"` uses, each phase-1 length and variant has a budget of $10^8$ nodes, shared equally among its subtrees. A subtree that uses up its share stops, at the same node whatever the threads do, so the moves are the same on any number of threads (checked on 4 and 16). The budget binds on positions like the transposition; the 200 random positions used at most about 7 million nodes each. The search gives up after $4 \times 10^8$ nodes without a solution.

### Variants

A solution of a related position can be turned into one of the position itself:

- **Relabeled.** Each label $l$ becomes $l + 1$ (20 becomes 1), so the pairs are 20 and 1, 2 and 3, and so on. Phase 1 sees a different coset, and the solution of the relabeled position followed by one left rotation solves the position.
- **Inverse.** The solution of the inverse permutation, reversed with each rotation inverted.
- **Mirror image.** The position seen in the mirror $P \to 3 - P$ (mod 20), which keeps $F$ and turns right rotations into left ones.

The library searches the first 1 to 8 of the combinations, interleaving their phase-1 lengths, and keeps the shortest solution. `TopSpinSolve` uses two, the position and its relabeled form, which helps a little (48.5 steps against 49.1 by one phase-1 length) at no extra time. The inverse and the mirror image barely helped.

## Tables

| Table | Entries | Memory | Build time |
|---|---|---|---|
| Phase 2: distance and elementary moves for each element of $H$ | 7,257,600 | 14.5 MB | 1 s |
| Coloring distances | $2^{20}$ | 1 MB | 0.03 s |
| Matching and parity distances | 1,309,458,150 | 655 MB | 114 s, or 0.3 s from a cached file |
| Cosets within 16 steps of the goal | 45,780,118 | 1 GB | 2–3 s |

The times are on 16 threads. The matching and parity table is built breadth first: forward from the goal for the first half of the states, then backward, where each state not yet reached checks its 19 successors for one in the last layer. Built only forward it took 237 s. While it is built it takes another 1.3 GB, one byte per state. With it cached, the tables are ready in 3 to 4.5 s.

## Building

CMake builds the library and a benchmark program into `build/` at the repository root (gitignored):

```bash
cmake -S src/c/topspin_twophase -B build/topspin_twophase -DCMAKE_BUILD_TYPE=Release
cmake --build build/topspin_twophase --config Release
```

On Windows run this from an "x64 Native Tools" prompt, as for [A401118_SCIP](A401118_SCIP.md#building-the-scip-library). The code also compiles with gcc, with or without OpenMP, and gives the same moves there. Without OpenMP the search runs on one thread.

The benchmark reads 20 labels per position from a file, then the number of variants and one or more limits in milliseconds (0 stops at the first solution; $-k$ searches the first $k$ phase-1 lengths). The environment variable `TOPSPIN_TP_CACHE` names the file that caches the matching and parity table, the same file `TopSpinSolve` uses:

```bash
TOPSPIN_TP_CACHE=build/topspin_pairing.bin build/topspin_twophase_bench positions.txt 2 0 -1 100
```

## C interface

- `int topspin_tp_init(const char *cache, int threads)` builds the tables and returns 0, or -1 when memory runs out. `cache` names the file of the matching and parity table, which is read when it is complete and written after the table is built; it may be empty. `threads` 0 uses every core.
- `int topspin_tp_solve(const int *state, double limit, int variants, int *out, int outMax)` takes the state as `TopSpinSolve` does and writes the steps to `out`: 0 for `F` and $r$ for a right rotation by $r$ positions. A limit of $t \ge 0$ searches for $t$ milliseconds (at least until a first solution, for at most 20 s more); $-k$ searches $k$ phase-1 lengths in the reproducible mode. It returns the number of steps, or -1 (not set up), -2 (not a permutation of 1 to 20), -3 (no solution within the limit or the budget) or -4 (`out` too short).
- `void topspin_tp_free(void)` releases the tables, and `void topspin_tp_stats(long long *out)` gives the nodes searched and phase-1 solutions completed by the last solve, and the number of cosets near the goal.

`TopSpinSolve` loads the library with `ForeignFunctionLoad` the way [`A401118SCIP`](A401118_SCIP.md#loading-it) does, passing the state with `RawMemoryExport` and reading the steps back with `RawMemoryImport`. It replays every solution before returning it.
