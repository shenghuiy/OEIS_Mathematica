(* Tests for src/wolfram/A401118Incremental.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118Incremental.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only the four documented functions are public; helpers and pattern variables stay in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`n", "OEIS`m", "OEIS`x", "OEIS`f", "OEIS`solve", "OEIS`lcmTrianglesC", "OEIS`a401118Run", "OEIS`lcmTriangleMax",
    "OEIS`Private`lcmTrianglesC", "OEIS`Private`a401118Run", "OEIS`Private`lcmTriangleMax"},
  {False, False, False, False, False, False, False, False, True, True, True},
  TestID -> "only-documented-public"
]

(* Plain calls solve with LinearOptimization (lcmTriangleMax); m = 6 needs a solve, for the triangle {2, 3, 6} *)

VerificationTest[
  Block[{OEIS`Private`lcmTriangleMax = (Throw["lo"] &)}, Catch[OEIS`A401118List[6]]],
  "lo",
  TestID -> "plain-call-uses-linearoptimization"
]


(* Examples from docs/A401118Incremental.md *)

VerificationTest[OEIS`LCMTriangles[12], {{2, 3, 6}, {2, 5, 10}, {3, 4, 12}, {4, 6, 12}}, TestID -> "example-triangles-12"]

VerificationTest[{OEIS`A401118Incremental[6], OEIS`A401118Incremental[12]}, {5, 10}, TestID -> "example-a6-a12"]

VerificationTest[
  Module[{s = OEIS`LCMTriangleFreeSubset[12]},
    {Length[s], NoneTrue[OEIS`LCMTriangles[12], SubsetQ[s, #] &]}],
  {10, True},
  TestID -> "example-subset-12"
]


(* Every case below keeps n < 20, so the file runs quickly with LinearOptimization. Larger n are checked against the b-file
   in docs/A401118Incremental.md, and with SCIP in test/wolfram/A401118_SCIP.wlt. *)


(* The first 19 terms of the OEIS DATA section *)

VerificationTest[
  OEIS`A401118List[19],
  {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16},
  TestID -> "oeis-data-19"
]


(* LCMTriangles against the definition *)

VerificationTest[
  OEIS`LCMTriangles[19] ===
    SortBy[Select[Subsets[Range[19], {3}], LCM[#[[1]], #[[2]]] == LCM[#[[2]], #[[3]]] == LCM[#[[1]], #[[3]]] &], {Last, First}],
  True,
  TestID -> "triangles-vs-definition"
]

(* Brute force over all subsets of {1..14} *)

VerificationTest[
  Module[{tris},
    Table[
      tris = Select[Subsets[Range[n], {3}], LCM[#[[1]], #[[2]]] == LCM[#[[2]], #[[3]]] == LCM[#[[1]], #[[3]]] &];
      Max[Length /@ Select[Subsets[Range[n]], Function[s, NoneTrue[tris, SubsetQ[s, #] &]]]],
      {n, 14}] === OEIS`A401118List[14]],
  True,
  TestID -> "brute-force-14"
]

(* The witness is triangle-free and has a(n) elements *)

VerificationTest[
  Module[{s = OEIS`LCMTriangleFreeSubset[19]},
    {Length[s], NoneTrue[OEIS`LCMTriangles[19], SubsetQ[s, #] &], SubsetQ[Range[19], s]}],
  {16, True, True},
  TestID -> "witness-19"
]


(* Formulas from the OEIS entry, for n <= 19 *)

VerificationTest[
  Module[{a = OEIS`A401118List[19]},
    {Union[Differences[a]], AllTrue[Prime[Range[2, PrimePi[19]]], a[[#]] == a[[# - 1]] + 1 &],
     AllTrue[Range[19], a[[#]] <= # - Floor[#/6] &]}],
  {{0, 1}, True, True},
  TestID -> "formulas"
]

VerificationTest[OEIS`A401118Incremental[19], OEIS`A401118List[19][[19]], TestID -> "single-term-vs-list"]


(* Invalid arguments *)

VerificationTest[OEIS`A401118Incremental[0], $Failed, {OEIS`A401118Incremental::posint}, TestID -> "message-a-zero"]
VerificationTest[OEIS`A401118List[2.5], $Failed, {OEIS`A401118List::posint}, TestID -> "message-list-real"]
VerificationTest[OEIS`LCMTriangles[-3], $Failed, {OEIS`LCMTriangles::posint}, TestID -> "message-triangles-negative"]
VerificationTest[OEIS`LCMTriangleFreeSubset["x"], $Failed, {OEIS`LCMTriangleFreeSubset::posint}, TestID -> "message-subset-string"]
