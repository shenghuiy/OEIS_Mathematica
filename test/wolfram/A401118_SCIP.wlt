(* Tests for src/wolfram/A401118_SCIP.wl. Cases that can run LinearOptimization keep n < 20; the larger ones run only with
   the SCIP library built (lib/ at the repository root) and pass trivially without it. *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118_SCIP.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only A401118SCIP is public; the helpers and their variables stay in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`a401118SCIPCliques", "OEIS`a401118SCIPSet", "OEIS`a401118LPSolve", "OEIS`a401118SCIPSolve", "OEIS`a401118SCIPFunction",
    "OEIS`n", "OEIS`x", "OEIS`vars", "OEIS`cliques", "OEIS`solve", "OEIS`method",
    "OEIS`Private`a401118SCIPSet", "OEIS`Private`a401118LPSolve", "OEIS`Private`a401118SCIPFunction"},
  {False, False, False, False, False, False, False, False, False, False, False, True, True, True},
  TestID -> "only-A401118SCIP-public"
]

VerificationTest[Options[OEIS`A401118SCIP], {Method -> Automatic}, TestID -> "method-option"]


(* Examples from docs/A401118_SCIP.md *)

VerificationTest[OEIS`Private`a401118SCIPCliques[6], {{2, 3, 6}}, TestID -> "example-cliques-6"]

VerificationTest[
  {OEIS`A401118SCIP[12], OEIS`A401118SCIP[12, Method -> "LinearOptimization"]},
  {10, 10},
  TestID -> "example-a12"
]


(* The first 19 terms of the OEIS DATA section, with each method *)

VerificationTest[
  Module[{data = {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16}},
    {OEIS`A401118SCIP /@ Range[19], OEIS`A401118SCIP[#, Method -> "LinearOptimization"] & /@ Range[19]} === {data, data}],
  True,
  TestID -> "oeis-data-19"
]


(* The cliques: each has all pairwise LCMs equal, and together they cover every LCM triangle *)

VerificationTest[
  AllTrue[OEIS`Private`a401118SCIPCliques[60], Length[Union[LCM @@@ Subsets[#, {2}]]] == 1 &],
  True,
  TestID -> "cliques-are-lcm-cliques"
]

VerificationTest[
  Module[{tri, cl},
    tri = Select[Subsets[Range[40], {3}], Equal @@ LCM @@@ Subsets[#, {2}] &];
    cl = OEIS`Private`a401118SCIPCliques[40];
    AllTrue[tri, Function[t, AnyTrue[cl, SubsetQ[#, t] &]]]],
  True,
  TestID -> "cliques-cover-triangles"
]

(* No LCM triangle below 6, so no program to solve *)

VerificationTest[
  {OEIS`Private`a401118SCIPCliques[5], OEIS`Private`a401118SCIPSet[5, OEIS`Private`a401118LPSolve]},
  {{}, {1, 2, 3, 4, 5}},
  TestID -> "no-cliques-below-6"
]

(* The optimal subset from LinearOptimization has a(19) = 16 elements and no LCM triangle *)

VerificationTest[
  Module[{s = OEIS`Private`a401118SCIPSet[19, OEIS`Private`a401118LPSolve]},
    {Length[s], NoneTrue[Subsets[s, {3}], Equal @@ LCM @@@ Subsets[#, {2}] &]}],
  {16, True},
  TestID -> "lp-subset-valid-19"
]


(* Choosing the solver *)

VerificationTest[
  With[{f = OEIS`Private`a401118SCIPFunction[]},
    {f === $Failed || Head[f] === ForeignFunction,
     OEIS`Private`a401118SCIPSolver[Automatic] === If[f === $Failed, OEIS`Private`a401118LPSolve, OEIS`Private`a401118SCIPSolve[f]],
     OEIS`Private`a401118SCIPSolver["LinearOptimization"] === OEIS`Private`a401118LPSolve}],
  {True, True, True},
  TestID -> "automatic-picks-scip-when-found"
]

(* Without the library, Automatic falls back to LinearOptimization and "SCIP" is an error *)

VerificationTest[
  Block[{OEIS`Private`a401118SCIPFunction = ($Failed &)},
    {OEIS`A401118SCIP[19], OEIS`A401118SCIP[19, Method -> "SCIP"]}],
  {16, $Failed},
  {OEIS`A401118SCIP::noscip},
  TestID -> "no-scip-fallback"
]


(* With the SCIP library built: the whole DATA section, b-file values, and a valid optimal subset *)

VerificationTest[
  If[OEIS`Private`a401118SCIPFunction[] === $Failed, True,
    Module[{s = OEIS`Private`a401118SCIPSet[150, OEIS`Private`a401118SCIPSolver["SCIP"]]},
      (OEIS`A401118SCIP[#, Method -> "SCIP"] & /@ Range[73]) ===
        {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16, 17, 18, 19, 19, 20, 21, 22, 23,
         24, 24, 25, 26, 27, 28, 28, 29, 30, 31, 32, 32, 33, 33, 34, 35, 35, 36, 37, 37, 38, 39, 40, 41, 42, 42,
         43, 43, 44, 45, 46, 46, 47, 48, 48, 49, 50, 50, 51, 52, 53, 53, 54, 54, 55} &&
       (OEIS`A401118SCIP[#, Method -> "SCIP"] & /@ {100, 150, 200}) === {76, 111, 146} &&
       Length[s] == 111 && NoneTrue[Subsets[s, {3}], Equal @@ LCM @@@ Subsets[#, {2}] &]]],
  True,
  TestID -> "scip-if-built"
]


(* Invalid arguments *)

VerificationTest[OEIS`A401118SCIP[12, Method -> "Gurobi"], $Failed, {OEIS`A401118SCIP::method}, TestID -> "message-method"]
VerificationTest[OEIS`A401118SCIP[0], $Failed, {OEIS`A401118SCIP::posint}, TestID -> "message-posint"]
VerificationTest[OEIS`A401118SCIP[2.5, Method -> "SCIP"], $Failed, {OEIS`A401118SCIP::posint}, TestID -> "message-posint-with-method"]
