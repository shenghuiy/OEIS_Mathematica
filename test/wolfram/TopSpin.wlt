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

VerificationTest[OEIS`TopSpinSolve[Range[19]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-short-state"]
VerificationTest[OEIS`TopSpinSolve[ConstantArray[1, 20]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-duplicate-state"]
VerificationTest[OEIS`TopSpinSolve[ReplacePart[Range[20], 1 -> x]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-symbolic-state"]
VerificationTest[OEIS`TopSpinSolve[N[Range[20]]], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-inexact-state"]
VerificationTest[OEIS`TopSpinSolve["123"], $Failed, {OEIS`TopSpinSolve::state}, TestID -> "reject-nonlist-state"]
VerificationTest[OEIS`TopSpinApply[Range[19], {}], $Failed, {OEIS`TopSpinApply::state}, TestID -> "apply-reject-invalid-state"]
VerificationTest[OEIS`TopSpinApply[Range[20], "RF"], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-nonlist-moves"]
VerificationTest[OEIS`TopSpinApply[Range[20], {"R", "X"}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-unknown-move"]
VerificationTest[OEIS`TopSpinApply[Range[20], {1}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-integer-move"]
VerificationTest[OEIS`TopSpinApply[Range[20], {_String}], $Failed, {OEIS`TopSpinApply::moves}, TestID -> "reject-pattern-move"]
