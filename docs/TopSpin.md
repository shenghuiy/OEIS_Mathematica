# TopSpin solver

[`src/wolfram/TopSpin.wl`](../src/wolfram/TopSpin.wl) finds a sequence of legal moves for any arrangement of the standard 20-token TopSpin puzzle. It uses Wolfram Language's native `GroupElementToWord`, the counterpart of generator-word recovery with GAP's `PreImagesRepresentative`.

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

`Length[moves]` counts elementary moves. `Counts[moves]` gives the number of each move. The result solves the fixed-position target `Range[20]`, including its orientation.

`TopSpinSolve[Range[20]]` returns `{}`. Both functions reject states that are not exact permutations of `Range[20]`, issuing a message and returning `$Failed`. `TopSpinApply` also rejects move lists containing anything other than the three strings above.

## Recover a word directly

The package wraps this native computation and checks its result by replaying the moves.

```wolfram
group = PermutationGroup[{
  Cycles[{Range[20]}],
  Cycles[{{1, 4}, {2, 3}}]
}];
target = FindPermutation[state, Range[20]];
word = GroupElementToWord[group, target];
GroupElementFromWord[group, word] === target
(* True *)
moves = word /. {1 -> "R", -1 -> "L", 2 -> "F", -2 -> "F"};
```

The generators are rotation and flip, in that order. A negative word entry denotes an inverse generator. The flip is its own inverse. `FindPermutation[state, Range[20]]` maps the current token positions to their solved positions, so the solver uses this permutation without taking its inverse.

Rotation and flip generate the symmetric group on 20 points. A one-position rotation is odd, so the full move group is not the alternating group. The solver operates on a permutation-group representation and recovers a word in its generators without listing all `20!` states.

The native word algorithm uses a table of coset representatives of group stabilizers. It does not promise a shortest solution, a fixed word length, or the same word across Wolfram versions. The package adds no shortest-path search or move-count optimization.

## Tests

```wolfram
TestReport["test/wolfram/TopSpin.wlt"]
```

The 22 tests cover move semantics, exact orientation, an odd transposition, a noncommuting scramble, ten seeded arbitrary permutations, and invalid input. Independent list operations replay the noncommuting and random solutions. The tests also check public symbol names.

## References

- [Wolfram Language: GroupElementToWord](https://reference.wolfram.com/language/ref/GroupElementToWord.html).
- [Wolfram Language: GroupElementFromWord](https://reference.wolfram.com/language/ref/GroupElementFromWord.html).
- [GAP: expressing group elements as words in generators](https://gap-system.github.io/gap/doc/ref/chap39.html#X87B9588878D5BA3C).
- John H. Wilson, [Permutation Puzzles](https://www.jstor.org/stable/2686788), The College Mathematics Journal 24, 163-165, 1993.
