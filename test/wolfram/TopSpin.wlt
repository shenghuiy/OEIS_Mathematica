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

VerificationTest[OEIS`TopSpinApply[Range[20], {}], Range[20], TestID -> "apply-empty"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"R"}], Join[{20}, Range[19]], TestID -> "apply-right"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"L"}], Join[Range[2, 20], {1}], TestID -> "apply-left"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"F"}], Join[{4, 3, 2, 1}, Range[5, 20]], TestID -> "apply-flip"]

VerificationTest[
  OEIS`TopSpinApply[Range[20], {"R", "F"}],
  Join[{3, 2, 1, 20}, Range[4, 19]],
  TestID -> "apply-left-to-right"
]

VerificationTest[
  OEIS`TopSpinApply[Range[20], #] & /@ {{"R3"}, {"L12"}, {"R25", "F"}},
  {Join[Range[18, 20], Range[17]], Join[Range[13, 20], Range[12]], Join[{19, 18, 17, 16, 20}, Range[15]]},
  TestID -> "apply-compressed-rotations"
]

VerificationTest[OEIS`TopSpinSolve[Range[20]], {}, TestID -> "solve-identity"]

VerificationTest[
  AllTrue[{1, 7, 19}, Function[shift,
    With[{state = RotateRight[Range[20], shift]},
      OEIS`TopSpinApply[state, OEIS`TopSpinSolve[state]] === Range[20]
    ]
  ]],
  True,
  TestID -> "solve-rotations-exact-positions"
]

VerificationTest[
  Module[{state = ReplacePart[Range[20], {19 -> 20, 20 -> 19}], moves},
    moves = OEIS`TopSpinSolve[state];
    OEIS`TopSpinApply[state, moves] === Range[20]
  ],
  True,
  TestID -> "example-odd-transposition"
]

VerificationTest[
  Module[{state = Join[{3, 2, 1, 20}, Range[4, 19]], moves},
    moves = OEIS`TopSpinSolve[state];
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
      Module[{moves = OEIS`TopSpinSolve[state]},
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
  OEIS`TopSpinSolve /@ {Join[{4, 3, 2, 1}, Range[5, 20]], RotateRight[Range[20], 7], Join[{3, 2, 1, 20}, Range[4, 19]]},
  {{"F"}, ConstantArray["L", 7], {"F", "L"}},
  TestID -> "solve-short-scrambles"
]

VerificationTest[
  Length /@ OEIS`TopSpinSolve /@ {Reverse[Range[20]], ReplacePart[Range[20], {19 -> 20, 20 -> 19}]},
  {190, 69},
  TestID -> "solve-word-lengths"
]

VerificationTest[
  OEIS`TopSpinSolve[#, "CompressRotations" -> True] & /@ {
    Range[20], Join[{4, 3, 2, 1}, Range[5, 20]], RotateRight[Range[20], 7], Join[{3, 2, 1, 20}, Range[4, 19]]},
  {{}, {"F"}, {"L7"}, {"F", "L"}},
  TestID -> "solve-compressed-short-scrambles"
]

VerificationTest[
  Length /@ (OEIS`TopSpinSolve[#, "CompressRotations" -> True] & /@ {Reverse[Range[20]], ReplacePart[Range[20], {19 -> 20, 20 -> 19}]}),
  {148, 65},
  TestID -> "solve-compressed-step-counts"
]

VerificationTest[
  BlockRandom[
    SeedRandom[20261030];
    AllTrue[Table[RandomSample[Range[20]], {10}], Function[state,
      Module[{moves = OEIS`TopSpinSolve[state], steps = OEIS`TopSpinSolve[state, "CompressRotations" -> True]},
        OEIS`TopSpinSolve[state, "CompressRotations" -> False] === moves &&
        steps === (If[Length[#] == 1, First[#], First[#] <> IntegerString[Length[#]]] & /@ Split[moves]) &&
        OEIS`TopSpinApply[state, steps] === Range[20]
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
      AllTrue[Table[RandomSample[Range[20]], {10}], reducedQ[StringJoin[OEIS`TopSpinSolve[#]]] &]
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

VerificationTest[OEIS`TopSpinSolve[Range[19]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-short-state"]
VerificationTest[OEIS`TopSpinSolve[ConstantArray[1, 20]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-duplicate-state"]
VerificationTest[OEIS`TopSpinSolve[ReplacePart[Range[20], 1 -> x]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-symbolic-state"]
VerificationTest[OEIS`TopSpinSolve[N[Range[20]]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-inexact-state"]
VerificationTest[OEIS`TopSpinSolve["123"], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-nonlist-state"]
VerificationTest[OEIS`TopSpinSolve[Range[20], "CompressRotations" -> 1], $Failed, {OEIS`TopSpinSolve::opttf}, TestID -> "reject-compress-option-value"]
VerificationTest[OEIS`TopSpinSolve[Range[20], "Compress" -> True], $Failed, {OEIS`TopSpinSolve::optx}, TestID -> "reject-unknown-option"]
VerificationTest[OEIS`TopSpinApply[Range[19], {}], $Failed, {OEIS`TopSpinApply::state}, TestID -> "apply-reject-invalid-state"]
VerificationTest[OEIS`TopSpinApply[Range[20], "RF"], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-nonlist-moves"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"R", "X"}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-unknown-move"]
VerificationTest[OEIS`TopSpinApply[Range[20], {1}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-integer-move"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"R0"}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-zero-rotation-move"]
VerificationTest[OEIS`TopSpinApply[Range[20], {_String}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-pattern-move"]
