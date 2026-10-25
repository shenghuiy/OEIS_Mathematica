(* Tests for src/wolfram/A401118.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only the four documented functions are public; helpers and pattern variables stay in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`n", "OEIS`m", "OEIS`x", "OEIS`f", "OEIS`solve", "OEIS`lcmTrianglesC", "OEIS`a401118Run", "OEIS`a401118DefaultSolver",
    "OEIS`Private`lcmTrianglesC", "OEIS`Private`a401118Run", "OEIS`Private`a401118DefaultSolver"},
  {False, False, False, False, False, False, False, False, True, True, True},
  TestID -> "only-documented-public"
]

(* Loading A401118.wl alone (or again) gives the LinearOptimization solver; A401118_SCIP.wl's Method option is not defined by it *)

VerificationTest[
  OEIS`Private`a401118DefaultSolver[OEIS`A401118] === OEIS`Private`lcmTriangleMax,
  True,
  TestID -> "default-solver-linearoptimization"
]


(* Examples from docs/A401118.md *)

VerificationTest[OEIS`LCMTriangles[12], {{2, 3, 6}, {2, 5, 10}, {3, 4, 12}, {4, 6, 12}}, TestID -> "example-triangles-12"]

VerificationTest[{OEIS`A401118[6], OEIS`A401118[12]}, {5, 10}, TestID -> "example-a6-a12"]

VerificationTest[
  Module[{s = OEIS`LCMTriangleFreeSubset[12]},
    {Length[s], NoneTrue[OEIS`LCMTriangles[12], SubsetQ[s, #] &]}],
  {10, True},
  TestID -> "example-subset-12"
]

VerificationTest[Length[OEIS`LCMTriangles[656]], 6225, TestID -> "example-triangle-count-656"]


(* The DATA section of A401118 *)

VerificationTest[
  OEIS`A401118List[73],
  {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, 17, 18, 19, 19, 20, 21, 22, 23, 24, 24,
   25, 26, 27, 28, 28, 29, 30, 31, 32, 32, 33, 33, 34, 35, 35, 36, 37, 37, 38, 39, 40, 41, 42, 42, 43, 43, 44, 45, 46, 46,
   47, 48, 48, 49, 50, 50, 51, 52, 53, 53, 54, 54, 55},
  TestID -> "oeis-data"
]

(* b-file values (computed by the entry's author with SCIP and HiGHS) up to n = 150 *)

VerificationTest[
  OEIS`A401118List[150],
  {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, 17, 18, 19, 19, 20, 21, 22, 23, 24, 24,
   25, 26, 27, 28, 28, 29, 30, 31, 32, 32, 33, 33, 34, 35, 35, 36, 37, 37, 38, 39, 40, 41, 42, 42, 43, 43, 44, 45, 46, 46,
   47, 48, 48, 49, 50, 50, 51, 52, 53, 53, 54, 54, 55, 56, 57, 58, 58, 58, 59, 60, 61, 62, 63, 63, 64, 65, 66, 67, 68, 69,
   69, 70, 71, 72, 73, 73, 74, 75, 75, 76, 77, 77, 78, 79, 79, 80, 81, 81, 82, 83, 84, 84, 85, 85, 86, 87, 87, 88, 88, 88,
   89, 90, 91, 92, 93, 93, 94, 95, 96, 97, 98, 98, 99, 100, 101, 102, 103, 103, 104, 104, 105, 106, 106, 107, 108, 109, 109, 110, 111, 111},
  TestID -> "b-file-150"
]


(* LCMTriangles against the definition *)

VerificationTest[
  OEIS`LCMTriangles[80] ===
    SortBy[Select[Subsets[Range[80], {3}], LCM[#[[1]], #[[2]]] == LCM[#[[2]], #[[3]]] == LCM[#[[1]], #[[3]]] &], {Last, First}],
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
  Module[{s = OEIS`LCMTriangleFreeSubset[120]},
    {Length[s], NoneTrue[OEIS`LCMTriangles[120], SubsetQ[s, #] &], SubsetQ[Range[120], s]}],
  {88, True, True},
  TestID -> "witness-120"
]


(* Formulas from the OEIS entry, for n <= 150 *)

VerificationTest[
  Module[{a = OEIS`A401118List[150]},
    {Union[Differences[a]], AllTrue[Prime[Range[2, PrimePi[150]]], a[[#]] == a[[# - 1]] + 1 &],
     AllTrue[Range[150], a[[#]] <= # - Floor[#/6] &]}],
  {{0, 1}, True, True},
  TestID -> "formulas"
]

VerificationTest[OEIS`A401118[100], OEIS`A401118List[100][[100]], TestID -> "single-term-vs-list"]




(* Invalid arguments *)

VerificationTest[OEIS`A401118[0], $Failed, {OEIS`A401118::posint}, TestID -> "message-a-zero"]
VerificationTest[OEIS`A401118List[2.5], $Failed, {OEIS`A401118List::posint}, TestID -> "message-list-real"]
VerificationTest[OEIS`LCMTriangles[-3], $Failed, {OEIS`LCMTriangles::posint}, TestID -> "message-triangles-negative"]
VerificationTest[OEIS`LCMTriangleFreeSubset["x"], $Failed, {OEIS`LCMTriangleFreeSubset::posint}, TestID -> "message-subset-string"]
