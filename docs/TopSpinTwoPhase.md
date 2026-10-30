# TopSpin two-phase solver (prototype)

[`src/c/topspin_twophase/topspin_twophase.c`](../src/c/topspin_twophase/topspin_twophase.c) is a C prototype of Kociemba's two-phase method for the 20-token TopSpin puzzle of [`TopSpin.wl`](TopSpin.md). It counts compressed steps, as `TopSpinSolve[state, "CompressRotations" -> True]` does: a run of rotations is one step and each flip is one step. Over the 200 benchmark positions it averages 44 to 51 steps, depending on the time it is given, against 123.6 for `TopSpinSolve`. It needs about 1.7 GB of tables, which take about 2 minutes to build the first time. `TopSpinSolve` does not call it.

## Results

The 200 positions are `SeedRandom[1]; Table[RandomSample[Range[20]], {200}]`, as on the [TopSpin](TopSpin.md#performance) page. The two-phase times are on 16 threads (Windows, MSVC 19.44), not counting the tables. Every solution was replayed to the solved state.

| Solver | Steps, average | Steps, longest | Elementary moves, average | Elementary moves, longest | Flips, average | Time per solve |
|---|---|---|---|---|---|---|
| `TopSpinSolve` (stored table) | 123.6 | 185 | 179.9 | 261 | 61.4 | 0.46 ms |
| Two-phase, first solution | 51.1 | 59 | 97.8 | 120 | 25.4 | 12 ms (longest 0.22 s) |
| Two-phase, first phase-1 length | 49.1 | 59 | 94.1 | 115 | 24.4 | 76 ms (longest 1.3 s) |
| Two-phase, first two phase-1 lengths | 47.8 | 57 | 91.8 | 115 | 23.8 | 0.19 s (longest 3.1 s) |
| Two-phase, 0.1 s | 46.5 | 58 | 89.3 | 113 | 23.1 | 0.1 s |
| Two-phase, 1 s | 44.3 | 55 | 85.9 | 105 | 22.0 | 1 s |
| Two-phase, 1 s, four variants | 44.0 | 53 | 85.2 | 103 | 21.8 | 1 s |

The elementary moves are those of the same solutions with each step `Rk` or `Lk` written out, for comparison with `TopSpinSolve`'s default output. The search minimizes steps and, among solutions with the fewest steps, elementary moves. The rows by phase-1 length give the same moves on any number of threads; the rows by time do not. The four variants are the position, its inverse, its mirror image and the mirror image of its inverse.

On the first 20 positions, where `TopSpinSolve` averages 120.1 steps, four variants give 44.5 steps (longest 49) in 1 s and 41.7 steps (longest 47, 82.3 elementary moves) in 10 s.

Counting words gives a lower bound of about 27 to 29 steps (14 flips) for a typical position, so the shortest solutions lie somewhere between that and 44 steps.

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
- **Matching.** The exact distance of the matching alone: 654,729,075 one-byte entries, at most 28 steps and about 22 on average.
- **Near the goal.** The exact distance of every coset within 16 steps of the goal: 45,780,118 cosets, in a hash table of $2^{27}$ entries. A coset that is not in it is at least 18 steps away.

Phase 1 is deep: about 30 steps for a random position, against about 18 from counting words. Most of the search happens just above the 16-step region, where the bound changes from the tables to exact distances. Without that region, the first solution of a position took about 26 s instead of about 0.15 s.

### The search

As in Kociemba's solver, the search does not stop at the shortest phase 1. For each phase-1 length, from the lower bound upward, it finds every phase-1 solution of exactly that length and completes it with a phase-2 lookup. It moves on to longer phase 1 until the time runs out or the phase-1 length reaches the best total. Longer phase-1 solutions are much more numerous: the first benchmark position has 127,258 of length 30 and about 8.6 million of length 32, and the best total fell from 51 to 47 as the search reached length 33. A search that ran to the end would give a shortest solution, but the number of phase-1 solutions grows by about 15 times per two steps.

The subtrees near the root are searched in parallel (OpenMP). Each subtree keeps its own best solution, and the bests are merged in a fixed order, so a search that finishes whole phase-1 lengths gives the same moves on any number of threads.

## Tables

| Table | Entries | Memory | Build time |
|---|---|---|---|
| Phase 2: distance and elementary moves for each element of $H$ | 7,257,600 | 14.5 MB | 1 s |
| Coloring distances | $2^{20}$ | 1 MB | 0.03 s |
| Matching distances | 654,729,075 | 655 MB | 108 s, or 0.3 s from a cached file |
| Cosets within 16 steps of the goal | 45,780,118 | 1 GB | 2–3 s |

The times are on 16 threads. With the matching table cached, the tables are ready in 3.5 to 4.5 s. The matching table comes out the same byte for byte on every build.

## Building

CMake builds the library and a benchmark program into `build/` at the repository root (gitignored):

```bash
cmake -S src/c/topspin_twophase -B build/topspin_twophase -DCMAKE_BUILD_TYPE=Release
cmake --build build/topspin_twophase --config Release
```

On Windows run this from an "x64 Native Tools" prompt, as for [A401118_SCIP](A401118_SCIP.md#building-the-scip-library). The code also compiles with gcc, with or without OpenMP. Without OpenMP the search runs on one thread.

The benchmark reads 20 labels per position from a file, then the number of variants and one or more limits in milliseconds (0 stops at the first solution; $-k$ finishes the first $k$ phase-1 lengths). The environment variable `TOPSPIN_TP_CACHE` names the file that caches the matching table:

```bash
TOPSPIN_TP_CACHE=build/topspin_matching.bin build/topspin_twophase_bench positions.txt 1 0 -1 100
```

## Calling it from Wolfram

`topspin_tp_init(cache, threads)` builds the tables and returns 0 (or -1 when memory runs out). `cache` names the matching table's file and may be empty, and `threads` 0 uses every core. `topspin_tp_solve(state, limit, variants, out, outMax)` takes the state as `TopSpinSolve` does and writes the steps to `out`: 0 for `F` and $r$ for a right rotation by $r$ positions. A negative limit $-k$ finishes $k$ phase-1 lengths. It returns the number of steps, or a negative error code.

`ForeignFunctionLoad` and the C library do not resolve paths against `Directory[]`, so both paths are expanded first. From the repository root:

```wolfram
lib = ExpandFileName["build/topspin_twophase.dll"];
cache = ExpandFileName["build/topspin_matching.bin"];
tpInit = ForeignFunctionLoad[lib, "topspin_tp_init",
  {"RawPointer"::["UnsignedInteger8"], "CInt"} -> "CInt"];
tpSolve = ForeignFunctionLoad[lib, "topspin_tp_solve",
  {"RawPointer"::["CInt"], "CDouble", "CInt", "RawPointer"::["CInt"], "CInt"} -> "CInt"];
tpInit[RawMemoryExport[Append[ToCharacterCode[cache, "UTF-8"], 0], "UnsignedInteger8"], 0]
(* 0 *)

step[0] = "F"; step[1] = "R"; step[19] = "L";
step[r_ /; 2 <= r <= 10] := "R" <> IntegerString[r];
step[r_ /; 11 <= r <= 18] := "L" <> IntegerString[20 - r];
twoPhase[state_, limit_, variants_] := Module[{out = RawMemoryAllocate["CInt", 256], n},
  n = tpSolve[RawMemoryExport[state, "CInt"], N[limit], variants, out, 256];
  If[n < 0, $Failed, step /@ RawMemoryImport[out, {"List", n}]]];

Get["src/wolfram/TopSpin.wl"];
SeedRandom[1]; state = RandomSample[Range[20]];
moves = twoPhase[state, -1, 1];
{Length[moves], TopSpinApply[state, moves] === Range[20]}
(* {51, True} *)
```

In Mathematica 15.0.1, `tpInit` took 97 s the first time, writing the 655 MB cache, and 4.5 s after that. With a limit of $-1$, `twoPhase` solved the 200 positions in 70 to 80 ms each, with the same moves as the benchmark program, and every solution passed `TopSpinApply`.

## Joining TopSpinSolve

A possible interface, as with `A401118SCIP`'s `Method` option:

- `TopSpinSolve[state, Method -> "TwoPhase"]` loads `topspin_twophase` from `build/` (or a directory named by an environment variable) with `ForeignFunctionLoad`, builds the tables on the first call, and caches the matching table in a file. The default stays the stored table, which needs nothing outside the package.
- By default it finishes the first phase-1 length, which gives the same moves every time. `Method -> {"TwoPhase", "TimeLimit" -> t}` searches for `t` seconds instead.
- `"CompressRotations"` works as now: the steps become `"R3"`, `"L7"` and so on, or their elementary moves.
- Without the library, it gives a message and returns `$Failed`.

The cost is the memory and the first call. The matching table could be stored at 4 bits per entry (327 MB), and the 16-step table in $2^{26}$ entries (512 MB), which makes about 860 MB in all.
