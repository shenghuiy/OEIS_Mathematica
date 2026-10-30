VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "TopSpin.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

VerificationTest[
  Block[{$ContextPath = {}}, {Names["OEIS`TopSpin*"], Names["OEIS`topSpin*"]}],
  {{"OEIS`TopSpinApply", "OEIS`TopSpinSolve"}, {}},
  TestID -> "public-symbols"
]

VerificationTest[TopSpinApply[Range[20], {}], Range[20], TestID -> "apply-empty"]
VerificationTest[TopSpinApply[Range[20], {"R"}], Join[{20}, Range[19]], TestID -> "apply-right"]
VerificationTest[TopSpinApply[Range[20], {"L"}], Join[Range[2, 20], {1}], TestID -> "apply-left"]
VerificationTest[TopSpinApply[Range[20], {"F"}], Join[{4, 3, 2, 1}, Range[5, 20]], TestID -> "apply-flip"]

VerificationTest[
  TopSpinApply[Range[20], {"R", "F"}],
  Join[{3, 2, 1, 20}, Range[4, 19]],
  TestID -> "apply-left-to-right"
]

VerificationTest[
  TopSpinApply[Range[20], #] & /@ {{"R3"}, {"L12"}, {"R25", "F"}},
  {Join[Range[18, 20], Range[17]], Join[Range[13, 20], Range[12]], Join[{19, 18, 17, 16, 20}, Range[15]]},
  TestID -> "apply-compressed-rotations"
]

VerificationTest[TopSpinSolve[Range[20]], {}, TestID -> "solve-identity"]

VerificationTest[
  AllTrue[{1, 7, 19}, Function[shift,
    With[{state = RotateRight[Range[20], shift]},
      TopSpinApply[state, TopSpinSolve[state]] === Range[20]
    ]
  ]],
  True,
  TestID -> "solve-rotations-exact-positions"
]

VerificationTest[
  Module[{state = ReplacePart[Range[20], {19 -> 20, 20 -> 19}], moves},
    moves = TopSpinSolve[state];
    TopSpinApply[state, moves] === Range[20]
  ],
  True,
  TestID -> "example-odd-transposition"
]

VerificationTest[
  Module[{state = Join[{3, 2, 1, 20}, Range[4, 19]], moves},
    moves = TopSpinSolve[state];
    Fold[Function[{s, m}, Switch[m,
      "R", RotateRight[s], "L", RotateLeft[s],
      "F", Join[Reverse[s[[1 ;; 4]]], s[[5 ;; 20]]], _, $Failed
    ]], state, moves] === Range[20]
  ],
  True,
  TestID -> "solve-noncommuting-scramble-independent-replay"
]

VerificationTest[
  BlockRandom[
    SeedRandom[20261030];
    AllTrue[Table[RandomSample[Range[20]], {10}], Function[state,
      Module[{moves = TopSpinSolve[state]},
        ListQ[moves] && Fold[Function[{s, m}, Switch[m,
          "R", RotateRight[s], "L", RotateLeft[s],
          "F", Join[Reverse[s[[1 ;; 4]]], s[[5 ;; 20]]], _, $Failed
        ]], state, moves] === Range[20]
      ]
    ]]
  ],
  True,
  TestID -> "solve-random-permutations-independent-replay"
]

VerificationTest[
  TopSpinSolve /@ {Join[{4, 3, 2, 1}, Range[5, 20]], RotateRight[Range[20], 7], Join[{3, 2, 1, 20}, Range[4, 19]]},
  {{"F"}, ConstantArray["L", 7], {"F", "L"}},
  TestID -> "solve-short-scrambles"
]

VerificationTest[
  Length /@ TopSpinSolve /@ {Reverse[Range[20]], ReplacePart[Range[20], {19 -> 20, 20 -> 19}]},
  {190, 69},
  TestID -> "solve-word-lengths"
]

VerificationTest[
  TopSpinSolve[#, "CompressRotations" -> True] & /@ {
    Range[20], Join[{4, 3, 2, 1}, Range[5, 20]], RotateRight[Range[20], 7], Join[{3, 2, 1, 20}, Range[4, 19]]},
  {{}, {"F"}, {"L7"}, {"F", "L"}},
  TestID -> "solve-compressed-short-scrambles"
]

VerificationTest[
  Length /@ (TopSpinSolve[#, "CompressRotations" -> True] & /@ {Reverse[Range[20]], ReplacePart[Range[20], {19 -> 20, 20 -> 19}]}),
  {148, 65},
  TestID -> "solve-compressed-step-counts"
]

VerificationTest[
  BlockRandom[
    SeedRandom[20261030];
    AllTrue[Table[RandomSample[Range[20]], {10}], Function[state,
      Module[{moves = TopSpinSolve[state], steps = TopSpinSolve[state, "CompressRotations" -> True]},
        TopSpinSolve[state, "CompressRotations" -> False] === moves &&
        steps === (If[Length[#] == 1, First[#], First[#] <> IntegerString[Length[#]]] & /@ Split[moves]) &&
        TopSpinApply[state, steps] === Range[20]
      ]
    ]]
  ],
  True,
  TestID -> "solve-compressed-matches-runs"
]

VerificationTest[
  Module[{reducedQ = StringFreeQ[#, "RL" | "LR" | "FF" | StringRepeat["R", 11] | StringRepeat["L", 11]] &},
    AllTrue[Flatten[OEIS`Private`topSpinTable], reducedQ] &&
    BlockRandom[
      SeedRandom[20261030];
      AllTrue[Table[RandomSample[Range[20]], {10}], reducedQ[StringJoin[TopSpinSolve[#]]] &]
    ]
  ],
  True,
  TestID -> "table-and-solutions-reduced"
]

VerificationTest[Length /@ OEIS`Private`topSpinTable, Range[19, 1, -1], TestID -> "table-shape"]

VerificationTest[
  And @@ Flatten[Table[
    With[{
        p = Fold[Function[{s, m}, Switch[m,
          "R", RotateRight[s], "L", RotateLeft[s],
          "F", Join[Reverse[s[[1 ;; 4]]], s[[5 ;; 20]]], _, $Failed
        ]], Range[20], Characters[OEIS`Private`topSpinTable[[i, k]]]],
        b = 21 - i
      },
      p[[b + 1 ;;]] === Range[b + 1, 20] && p[[b]] == k
    ],
    {i, 19}, {k, 20 - i}
  ]],
  True,
  TestID -> "table-entries-independent-replay"
]

(* Method: the stored table, unless Method -> "TwoPhase" asks for the library built from src/c/topspin_twophase.
   The cases that call the library pass trivially when it is not built. With it, the first of them sets up the
   tables, about 4 s, or about 2 minutes the first time, which writes build/topspin_pairing.bin. *)

VerificationTest[Options[TopSpinSolve], {"CompressRotations" -> False, Method -> "Table"}, TestID -> "method-option"]

VerificationTest[
  BlockRandom[
    SeedRandom[20261030];
    AllTrue[Table[RandomSample[Range[20]], {3}], Function[state,
      SameQ[TopSpinSolve[state], TopSpinSolve[state, Method -> "Table"], TopSpinSolve[state, Method -> Automatic]]
    ]]
  ],
  True,
  TestID -> "method-table-is-default"
]

VerificationTest[
  TopSpinSolve[Range[20], Method -> #] & /@ {"Kociemba", {"TwoPhase", "Lengths" -> 2}},
  {$Failed, $Failed},
  {TopSpinSolve::method, TopSpinSolve::method},
  TestID -> "reject-method"
]

VerificationTest[
  TopSpinSolve[Range[20], Method -> #] & /@ {{"TwoPhase", "TimeLimit" -> 0}, {"TwoPhase", "TimeLimit" -> 1, "PhaseOneLengths" -> 2}},
  {$Failed, $Failed},
  {TopSpinSolve::method, TopSpinSolve::method},
  TestID -> "reject-two-phase-limits"
]

VerificationTest[
  Block[{OEIS`Private`topSpinTwoPhaseFunction = ($Failed &)}, TopSpinSolve[Range[20], Method -> "TwoPhase"]],
  $Failed,
  {TopSpinSolve::nolib},
  TestID -> "two-phase-without-library"
]

(* A library that finds no solution (code -3) leaves the stored table's moves *)

VerificationTest[
  Block[{OEIS`Private`topSpinTwoPhaseFunction = (Function[-3] &)},
    With[{state = Join[{3, 2, 1, 20}, Range[4, 19]]},
      {TopSpinSolve[state, Method -> "TwoPhase"], TopSpinSolve[state, Method -> "TwoPhase", "CompressRotations" -> True]} ===
        {TopSpinSolve[state], TopSpinSolve[state, "CompressRotations" -> True]}
    ]
  ],
  True,
  {TopSpinSolve::tpnone, TopSpinSolve::tpnone},
  TestID -> "two-phase-fallback-to-table"
]

VerificationTest[
  If[OEIS`Private`topSpinTwoPhaseFunction[] === $Failed, True,
    Module[{short = {Range[20], Join[{4, 3, 2, 1}, Range[5, 20]], RotateRight[Range[20], 7], Join[{3, 2, 1, 20}, Range[4, 19]]}},
      {TopSpinSolve[#, Method -> "TwoPhase"] & /@ short, TopSpinSolve[#, Method -> "TwoPhase", "CompressRotations" -> True] & /@ short} ===
        {{{}, {"F"}, ConstantArray["L", 7], {"F", "L"}}, {{}, {"F"}, {"L7"}, {"F", "L"}}}
    ]
  ],
  True,
  TestID -> "two-phase-short-scrambles"
]

VerificationTest[
  If[OEIS`Private`topSpinTwoPhaseFunction[] === $Failed, True,
    BlockRandom[
      SeedRandom[20261030];
      Module[{states = Table[RandomSample[Range[20]], {10}], moves, steps},
        moves = TopSpinSolve[#, Method -> "TwoPhase"] & /@ states;
        steps = TopSpinSolve[#, Method -> "TwoPhase", "CompressRotations" -> True] & /@ states;
        Length /@ steps === {38, 50, 52, 50, 47, 51, 35, 41, 51, 48} &&
        steps === Map[If[Length[#] == 1, First[#], First[#] <> IntegerString[Length[#]]] &, Split /@ moves, {2}] &&
        AllTrue[Transpose[{states, moves}], Function[sm,
          Fold[Function[{s, m}, Switch[m,
            "R", RotateRight[s], "L", RotateLeft[s],
            "F", Join[Reverse[s[[1 ;; 4]]], s[[5 ;; 20]]], _, $Failed
          ]], sm[[1]], sm[[2]]] === Range[20]
        ]] &&
        AllTrue[moves, StringFreeQ[StringJoin[#], "RL" | "LR" | "FF" | StringRepeat["R", 11] | StringRepeat["L", 11]] &]
      ]
    ]
  ],
  True,
  TestID -> "two-phase-random-permutations"
]

(* The transposition has every pair in its slot and the parity wrong, the hardest case for phase 1 (about 5 s) *)

VerificationTest[
  If[OEIS`Private`topSpinTwoPhaseFunction[] === $Failed, True,
    Module[{states = {Reverse[Range[20]], ReplacePart[Range[20], {19 -> 20, 20 -> 19}]}, steps},
      steps = TopSpinSolve[#, Method -> "TwoPhase", "CompressRotations" -> True] & /@ states;
      Length /@ steps === {41, 40} && And @@ MapThread[TopSpinApply[#1, #2] === Range[20] &, {states, steps}]
    ]
  ],
  True,
  TestID -> "two-phase-reversal-and-transposition"
]

VerificationTest[
  If[OEIS`Private`topSpinTwoPhaseFunction[] === $Failed, True,
    BlockRandom[
      SeedRandom[20261030];
      Module[{states = Table[RandomSample[Range[20]], {3}], one, two, timed},
        one = TopSpinSolve[#, Method -> "TwoPhase", "CompressRotations" -> True] & /@ states;
        two = TopSpinSolve[#, Method -> {"TwoPhase", "PhaseOneLengths" -> 2}, "CompressRotations" -> True] & /@ states;
        timed = TopSpinSolve[#, Method -> {"TwoPhase", "TimeLimit" -> 0.2}, "CompressRotations" -> True] & /@ states;
        And @@ Thread[Length /@ two <= Length /@ one] &&
        AllTrue[Join[Transpose[{states, two}], Transpose[{states, timed}]], TopSpinApply @@ # === Range[20] &]
      ]
    ]
  ],
  True,
  TestID -> "two-phase-limits"
]

VerificationTest[TopSpinSolve[Range[19]], $Failed, {TopSpinSolve::state}, TestID -> "reject-short-state"]
VerificationTest[TopSpinSolve[ConstantArray[1, 20]], $Failed, {TopSpinSolve::state}, TestID -> "reject-duplicate-state"]
VerificationTest[TopSpinSolve[ReplacePart[Range[20], 1 -> x]], $Failed, {TopSpinSolve::state}, TestID -> "reject-symbolic-state"]
VerificationTest[TopSpinSolve[N[Range[20]]], $Failed, {TopSpinSolve::state}, TestID -> "reject-inexact-state"]
VerificationTest[TopSpinSolve["123"], $Failed, {TopSpinSolve::state}, TestID -> "reject-nonlist-state"]
VerificationTest[TopSpinSolve[Range[20], "CompressRotations" -> 1], $Failed, {TopSpinSolve::opttf}, TestID -> "reject-compress-option-value"]
VerificationTest[TopSpinSolve[Range[20], "Compress" -> True], $Failed, {TopSpinSolve::optx}, TestID -> "reject-unknown-option"]
VerificationTest[TopSpinApply[Range[19], {}], $Failed, {TopSpinApply::state}, TestID -> "apply-reject-invalid-state"]
VerificationTest[TopSpinApply[Range[20], "RF"], $Failed, {TopSpinApply::moves}, TestID -> "reject-nonlist-moves"]
VerificationTest[TopSpinApply[Range[20], {"R", "X"}], $Failed, {TopSpinApply::moves}, TestID -> "reject-unknown-move"]
VerificationTest[TopSpinApply[Range[20], {1}], $Failed, {TopSpinApply::moves}, TestID -> "reject-integer-move"]
VerificationTest[TopSpinApply[Range[20], {"R0"}], $Failed, {TopSpinApply::moves}, TestID -> "reject-zero-rotation-move"]
VerificationTest[TopSpinApply[Range[20], {_String}], $Failed, {TopSpinApply::moves}, TestID -> "reject-pattern-move"]
