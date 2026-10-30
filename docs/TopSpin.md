# TopSpin solver

[`src/wolfram/TopSpin.wl`](../src/wolfram/TopSpin.wl) finds a sequence of legal moves for any arrangement of the standard 20-token TopSpin puzzle. It sifts the position through a stored table of short words (Minkwitz's method). A solve takes about 0.4 ms and averages about 180 moves. With `Method -> "TwoPhase"` it calls a C library instead, Kociemba's two-phase method, whose solutions are less than half as long.

## Solve a position

Load the package from the repository root and supply the labels in fixed-position order. Positions 1 through 4 are in the turnstile.

```wolfram
Get["src/wolfram/TopSpin.wl"];
state = ReplacePart[Range[20], {19 -> 20, 20 -> 19}];
moves = TopSpinSolve[state];
TopSpinApply[state, moves] === Range[20]
(* True *)
```

Read `moves` from left to right. Each string is one physical move.

| Move | Action |
|---|---|
| `"R"` | Rotate the entire track right by one position. The last entry becomes the first. |
| `"L"` | Rotate the entire track left by one position. The first entry becomes the last. |
| `"F"` | Reverse the four entries in positions 1 through 4. |

`Length[moves]` counts elementary moves. `Counts[moves]` gives the number of each move. The result solves the fixed-position target `Range[20]`, including its orientation. It never contains `"R", "L"`, `"L", "R"` or `"F", "F"` next to each other, or more than 10 rotations in a row.

`TopSpinSolve[Range[20]]` returns `{}`. Both functions reject states that are not exact permutations of `Range[20]`, issuing a message and returning `$Failed`. `TopSpinApply` also rejects move lists containing anything other than the three strings above and the rotation steps below.

### Compressed steps

On the physical puzzle, sliding the tokens several positions around the track is one motion. With `"CompressRotations" -> True`, `TopSpinSolve` writes each run of rotations as one step: `"R3"` rotates right by three positions and `"L7"` left by seven, while a run of one stays `"R"` or `"L"`. `Length[moves]` then counts these steps, with each flip still one step, and `TopSpinApply` executes them (it takes `"Rk"` and `"Lk"` for any positive integer `k`).

```wolfram
TopSpinSolve[RotateRight[Range[20], 7], "CompressRotations" -> True]
(* {"L7"} *)
TopSpinSolve[Join[{3, 2, 1, 20}, Range[4, 19]], "CompressRotations" -> True]
(* {"F", "L"} *)
```

A step is at most `"R10"` or `"L9"`, and two rotation steps are never next to each other, so the steps alternate between a rotation and `"F"`. The word is the same as without the option: only how rotations are written and counted changes. Over the 200 random positions in [Performance](#performance), solutions average 123.6 steps (longest 185) against 179.9 elementary moves, and about 61 of those steps are flips. The table was chosen for elementary length, not for steps, so these counts are not the fewest steps a table could give.

Any other option, or a value other than `True` or `False`, gives a message and `$Failed`.

### Two-phase solutions

`Method -> "TwoPhase"` solves the position with the C library built from [`src/c/topspin_twophase`](../src/c/topspin_twophase), an implementation of Kociemba's two-phase method described on its own page, [TopSpin two-phase solver](TopSpinTwoPhase.md). Its solutions are much shorter than the table's, in steps and in elementary moves, and `"CompressRotations"` writes them either way:

```wolfram
state = ReplacePart[Range[20], {19 -> 20, 20 -> 19}];
Length /@ {TopSpinSolve[state, "CompressRotations" -> True],
  TopSpinSolve[state, Method -> "TwoPhase", "CompressRotations" -> True]}
(* {65, 40} *)
```

The default, `Method -> "Table"` (or `Automatic`), is the stored table, which needs nothing outside the package.

| `Method` | Search |
|---|---|
| `"TwoPhase"` | The first phase-1 length that has solutions. The moves are the same on every run and every number of threads. |
| `{"TwoPhase", "PhaseOneLengths" -> k}` | The first `k` phase-1 lengths: longer, and as short or shorter. Also the same on every run. |
| `{"TwoPhase", "TimeLimit" -> t}` | `t` seconds, or longer when no solution has turned up by then. The moves can differ from run to run. |

Another value of `Method` gives a message and `$Failed`, and so does giving both `"TimeLimit"` and `"PhaseOneLengths"`. If the search finds nothing within its node budget (or 20 s past the time limit), `TopSpinSolve` gives `TopSpinSolve::tpnone` and returns the stored table's solution; none of the positions tried so far comes close to that.

The library is built with CMake into `build/` at the repository root, as described in [Building](TopSpinTwoPhase.md#building). `TopSpinSolve` looks for `topspin_twophase.dll` (`.so`, `.dylib`) there, or in the directory named by the environment variable `TOPSPIN_TWOPHASE_LIB`. Without it, `Method -> "TwoPhase"` gives `TopSpinSolve::nolib` and returns `$Failed`. The first call in a session sets up about 1.7 GB of tables, which takes about 4 s. The very first call also builds the largest table, about 2 minutes on 16 threads, and saves it as `topspin_pairing.bin` (655 MB) next to the library. The library is looked for and set up once per session, so restart the kernel after building it.

On 16 threads, `Method -> "TwoPhase"` solves a random position in about 25 ms, with the longest of the 200 in [Performance](#performance) taking 0.74 s. A single swap of two adjacent tokens is its hardest case, 4 to 8 s, for a 40-step solution.

## How it works

Rotation and flip generate the symmetric group on 20 points. A one-position rotation is odd, so the full move group is not the alternating group.

Applying a word to a state `s` gives `s[[p]]` for an index list `p`, and the solved state needs `p = Ordering[s]`. The solver writes that index list as a product of 19 table words, one for each base position 20, 19, ..., 2:

1. Start with `x = Ordering[state]`.
2. At base position `b`, the positions above `b` are already in place, so `k = x[[b]]` is at most `b`. If `k < b`, take entry `k` of the table row for `b`. Its moves leave positions `b + 1` through 20 alone and bring the token in position `k` to position `b`. Append the word to the solution, and compose `x` with the word's inverse, which puts `b` in place.
3. After position 2, `x` is the identity.

The concatenated words are then reduced. $R$ has order 20 and $F$ has order 2, so every word can be written as $R^{r_0} F R^{r_1} F \cdots F R^{r_k}$ with each $r_i$ taken mod 20. Where two table words meet, the rotation amounts add. When an amount between two flips becomes 0, the two flips cancel and the amounts on either side add in turn. Finally each $r$ is written as `R` repeated $r$ times when $r \le 10$, and as `L` repeated $20 - r$ times otherwise. Reduction removes about a quarter of the moves.

The row for base position `b` has `b - 1` entries, so the table holds 190 words with 2,806 moves in all, the longest 41. It is stored in the package as strings, so loading compiles nothing and takes about 10 ms. The solve is plain list code, so the moves do not depend on the Wolfram version.

## The word table

Minkwitz's algorithm fills the table. It runs through every reduced word in `R`, `L` and `F` in order of length and sifts each one through the base positions. At each position it either finds the slot for its target empty (or holding a longer word) and takes it, or strips the stored word off its front and moves on to the next position. A displaced word is sifted on in the same way. Every so often it also sifts the products of pairs of words in the same row, which is how the rows for low base positions get short words. Words longer than a cap are dropped, and the cap grows after a pass that leaves the table incomplete.

The private `topSpinBuildTable[iterations]` runs this. Its kernel is compiled with `FunctionCompile` on the first call, which takes about a minute, and is not compiled when the package loads. The stored table is `topSpinBuildTable[10^6]`: all reduced words through length 18 and some of length 19, with a pass over pairs every 20,000 words and a starting cap of 30. To rebuild it and compare (about 90 s, most of it compiling):

```wolfram
OEIS`Private`topSpinBuildTable[10^6] === OEIS`Private`topSpinTable
(* True *)
```

More words give shorter solutions, with diminishing returns. The base order matters too. Over the 200 random positions in [Performance](#performance), with 50,000 words, sifting positions 20 down to 2 beat 1 up to 19 and three other orders.

| Words sifted | Base order | Average solution | Longest | Build (after compiling) |
|---|---|---|---|---|
| 50,000 | 1, 2, ..., 19 | 255.6 | 357 | 0.4 s |
| 50,000 | 20, 19, ..., 2 | 212.4 | 336 | 0.4 s |
| 200,000 | 20, 19, ..., 2 | 191.5 | 291 | 1.6 s |
| 1,000,000 | 20, 19, ..., 2 | 179.9 | 261 | 8 s |
| 5,000,000 | 20, 19, ..., 2 | 176.2 | 256 | 33 s |

The build times are for the faster element-by-element version of the kernel used while choosing these settings, which takes about twice as long to compile. The package's kernel builds the same table.

## Performance

Over 200 random positions (`SeedRandom[1]; Table[RandomSample[Range[20]], {200}]`) in Mathematica 15.0.1:

| Method | Per solve | Average moves | Longest |
|---|---|---|---|
| `GroupElementToWord`, default options | 4.6 ms | 596.9 | 821 |
| `TopSpinSolve` (stored table) | 0.40 ms | 179.9 | 261 |
| `TopSpinSolve`, `Method -> "TwoPhase"` (16 threads) | 24 ms | 93.6 | 120 |

With `"CompressRotations" -> True` the stored table averages 123.6 steps (longest 185) and `Method -> "TwoPhase"` 48.5 steps (longest 60). `{"TwoPhase", "PhaseOneLengths" -> 2}` gives 47.0 steps (longest 57) in 60 ms. [TopSpin two-phase solver](TopSpinTwoPhase.md#results) has the two-phase solver's results with other limits.

The built-in `GroupElementToWord` also uses Minkwitz's method, but it rebuilds its stabilizer chain (about 4 ms) and its word table on every call. Sifting one position through the table takes only about 0.2 ms of that. More iterations shorten its words, but each call pays for them, since the table is rebuilt every time. On smaller samples, `MaxIterations -> 10^6` gave an average of 373 moves at 83 ms per call (20 positions), and `MaxIterations -> 5*10^6` with `Method -> {"Minkwitz", "InitMaxLength" -> 12}` gave 322 moves at 1.8 s per call (5 positions).

With the built-in, the same computation is:

```wolfram
group = PermutationGroup[{
  Cycles[{Range[20]}],
  Cycles[{{1, 4}, {2, 3}}]
}];
target = FindPermutation[state, Range[20]];
word = GroupElementToWord[group, target];
moves = word /. {1 -> "R", -1 -> "L", 2 -> "F", -2 -> "F"};
```

The generators are rotation and flip, in that order. A negative word entry denotes an inverse generator. The flip is its own inverse. The word it returns is not promised to be the same across Wolfram versions.

## Tests

```wolfram
TestReport["test/wolfram/TopSpin.wlt"]
```

The 44 tests cover move semantics, exact orientation, an odd transposition, a noncommuting scramble, ten seeded arbitrary permutations, and invalid input (including bad options, bad `Method` values and `"R0"`). Independent list operations replay the noncommuting and random solutions. Three short scrambles must come back as their shortest solutions (`{"F"}`, seven `"L"`, and `{"F", "L"}`, or `{"F"}`, `{"L7"}` and `{"F", "L"}` compressed), and the reversed track and the odd transposition as words of 190 and 69 moves, or 148 and 65 compressed steps. Compressed solutions of the random permutations must be the runs of the elementary ones and replay with `TopSpinApply`, which must also execute `"R3"`, `"L12"` and `"R25"`. The table must have rows of 19 down to 1 words, every entry must leave the positions above its base alone and bring its token to the base (replayed independently), and the table and the solutions must be reduced. The tests also check public symbol names. Rebuilding the table is not in the tests, since it takes about 90 s.

`Method -> "Table"` and `Automatic` must give the default's moves, and `Method -> "TwoPhase"` without the library must give `TopSpinSolve::nolib`, and with a library that finds nothing, `TopSpinSolve::tpnone` and the table's moves. The other two-phase tests pass trivially when the library is not built. With it, the short scrambles must come back as the same shortest solutions, the ten seeded permutations as solutions of 38, 50, 52, 50, 47, 51, 35, 41, 51 and 48 steps (reduced, replayed independently, and compressed as the runs of the elementary moves), and the reversed track and the odd transposition in 41 and 40 steps. `"PhaseOneLengths" -> 2` must give solutions no longer than the default, and `"TimeLimit" -> 0.2` valid ones. With the library, the file takes about 15 s, or about 2 minutes more the first time.

## References

- T. Minkwitz, [An algorithm for solving the factorization problem in permutation groups](https://doi.org/10.1006/jsco.1998.0202), Journal of Symbolic Computation 26, 89-100, 1998.
- [Wolfram Language: GroupElementToWord](https://reference.wolfram.com/language/ref/GroupElementToWord.html).
- [GAP: expressing group elements as words in generators](https://gap-system.github.io/gap/doc/ref/chap39.html#X87B9588878D5BA3C).
- John H. Wilson, [Permutation Puzzles](https://www.jstor.org/stable/2686788), The College Mathematics Journal 24, 163-165, 1993.
