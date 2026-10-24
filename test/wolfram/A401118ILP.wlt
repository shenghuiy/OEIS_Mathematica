(* Tests for src/wolfram/A401118ILP.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118ILP.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only A401118ILP is public; the helpers and their variables stay in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`a401118Cliques", "OEIS`a401118ILPSet", "OEIS`n", "OEIS`x", "OEIS`vars", "OEIS`cliques",
    "OEIS`Private`a401118ILPSet"},
  {False, False, False, False, False, False, True},
  TestID -> "only-A401118ILP-public"
]


(* The whole OEIS DATA section *)

VerificationTest[
  OEIS`A401118ILP /@ Range[73],
  {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, 17, 18, 19, 19, 20, 21, 22, 23,
   24, 24, 25, 26, 27, 28, 28, 29, 30, 31, 32, 32, 33, 33, 34, 35, 35, 36, 37, 37, 38, 39, 40, 41, 42, 42,
   43, 43, 44, 45, 46, 46, 47, 48, 48, 49, 50, 50, 51, 52, 53, 53, 54, 54, 55},
  TestID -> "oeis-data-1-73"
]

(* b-file values (Mark Ma, n = 1..656) *)

VerificationTest[OEIS`A401118ILP /@ {100, 150, 200}, {76, 111, 146}, TestID -> "b-file-100-150-200"]


(* The cliques: each has all pairwise LCMs equal, and together they cover every LCM triangle *)

VerificationTest[
  AllTrue[OEIS`Private`a401118Cliques[60], Length[Union[LCM @@@ Subsets[#, {2}]]] == 1 &],
  True,
  TestID -> "cliques-are-lcm-cliques"
]

VerificationTest[
  Module[{tri, cl},
    tri = Select[Subsets[Range[40], {3}], Equal @@ LCM @@@ Subsets[#, {2}] &];
    cl = OEIS`Private`a401118Cliques[40];
    AllTrue[tri, Function[t, AnyTrue[cl, SubsetQ[#, t] &]]]],
  True,
  TestID -> "cliques-cover-triangles"
]

(* The optimal subset has no LCM triangle *)

VerificationTest[
  Module[{s = OEIS`Private`a401118ILPSet[60]},
    {Length[s], NoneTrue[Subsets[s, {3}], Equal @@ LCM @@@ Subsets[#, {2}] &]}],
  {OEIS`A401118ILP[60], True},
  TestID -> "optimal-set-valid"
]

(* No LCM triangle below 6, so no program to solve *)

VerificationTest[
  {OEIS`Private`a401118Cliques[5], OEIS`Private`a401118ILPSet[5]},
  {{}, {1, 2, 3, 4, 5}},
  TestID -> "no-cliques-below-6"
]


(* Examples from docs/A401118ILP.md *)

VerificationTest[OEIS`Private`a401118Cliques[6], {{2, 3, 6}}, TestID -> "example-cliques-6"]
VerificationTest[OEIS`A401118ILP[100], 76, TestID -> "example-a100"]
