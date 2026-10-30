(* Tests for src/wolfram/A401118.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only A401118 is public; the helpers and the variables of the compiled functions stay in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`a401118Search", "OEIS`a401118KSubsets", "OEIS`a401118GoodQ", "OEIS`n", "OEIS`k", "OEIS`s",
    "OEIS`Private`a401118Search"},
  {False, False, False, False, False, False, True},
  TestID -> "only-A401118-public"
]


(* The first 24 terms of the OEIS DATA section *)

VerificationTest[
  A401118 /@ Range[24],
  {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, 17, 18, 19, 19},
  TestID -> "oeis-data-1-24"
]

(* The definition, with no compiled code: the Python program in the OEIS entry, translated *)

VerificationTest[
  Module[{pure},
    pure[n_] := SelectFirst[Range[n, 1, -1],
      AnyTrue[Subsets[Range[n], {#}],
        NoneTrue[Subsets[#, {3}], Equal @@ LCM @@@ Subsets[#, {2}] &] &] &, 0];
    A401118 /@ Range[16] === pure /@ Range[16]],
  True,
  TestID -> "vs-definition"
]

(* The same search with IncrementalObject["Subsets"] as the iterator *)

VerificationTest[
  OEIS`Private`a401118SearchIncremental /@ Range[0, 20] === OEIS`Private`a401118Search /@ Range[0, 20],
  True,
  TestID -> "incremental-object-agrees"
]

(* The compiled generator yields the k-subsets in the order of Subsets *)

VerificationTest[
  Module[{gen, ds},
    gen = FunctionCompile[OEIS`Private`a401118KSubsetsDecl,
      Function[{Typed[n, "MachineInteger"], Typed[k, "MachineInteger"]}, OEIS`Private`a401118KSubsets[n, k]]];
    ds = gen[7, 3];
    Table[ds["Next"], Binomial[7, 3]] === Subsets[Range[7], {3}]],
  True,
  TestID -> "k-subsets-order"
]


(* Examples from docs/A401118.md and the OEIS entry *)

VerificationTest[
  OEIS`Private`a401118GoodC /@ {{2, 3, 6}, {2, 5, 10}, {3, 4, 12}, {1, 2, 3, 4, 5}, {1, 3, 4, 5, 6}},
  {False, False, False, True, True},
  TestID -> "example-triangles"
]

VerificationTest[A401118[6], 5, TestID -> "example-a6"]
VerificationTest[A401118[12], 10, TestID -> "example-a12"]

(* {2, 5, 10} and {3, 4, 12} are disjoint LCM triangles in {1..12}, so at least two elements must go;
   removing 2 and 4 leaves no triangle *)

VerificationTest[
  OEIS`Private`a401118GoodC[Complement[Range[12], {2, 4}]],
  True,
  TestID -> "example-a12-witness"
]
