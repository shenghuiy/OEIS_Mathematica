(* Tests for src/wolfram/A401118_SCIP.wl. The SCIP cases pass trivially when src/c/a401118_scip/lib has no library. *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118_SCIP.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* No new public names: the Method option goes on the two packages' functions, the helpers stay in OEIS`Private`.
   Names["OEIS`*"] also holds the other packages' names when the whole suite runs in one kernel, so check by name. *)

VerificationTest[
  NameQ /@ {"OEIS`f", "OEIS`head", "OEIS`method", "OEIS`opts", "OEIS`s", "OEIS`a401118SCIPMethod", "OEIS`a401118SCIPSolve",
    "OEIS`a401118SCIPFunction", "OEIS`a401118SCIPILPSet",
    "OEIS`Private`a401118SCIPMethod", "OEIS`Private`a401118SCIPSolve", "OEIS`Private`a401118SCIPFunction", "OEIS`Private`a401118SCIPILPSet"},
  {False, False, False, False, False, False, False, False, False, True, True, True, True},
  TestID -> "only-documented-public"
]

VerificationTest[
  Options /@ {OEIS`A401118ILP, OEIS`A401118Incremental, OEIS`A401118List, OEIS`LCMTriangleFreeSubset},
  ConstantArray[{Method -> Automatic}, 4],
  TestID -> "method-option-defined"
]


(* Examples from docs/A401118_SCIP.md. Cases that can run LinearOptimization keep n < 20; only the SCIP-only case below goes higher. *)

VerificationTest[
  {OEIS`A401118ILP[19], OEIS`A401118ILP[19, Method -> "LinearOptimization"], OEIS`A401118ILP[19, Method -> "SCIP"] /. $Failed -> 16},
  {16, 16, 16},
  TestID -> "example-ilp-19"
]

VerificationTest[
  OEIS`A401118List[19, Method -> "LinearOptimization"] === OEIS`A401118List[19, Method -> Automatic],
  True,
  TestID -> "example-incremental-methods-agree-19"
]

VerificationTest[
  With[{f = OEIS`Private`a401118SCIPFunction[]},
    {f === $Failed || Head[f] === ForeignFunction,
     MatchQ[OEIS`Private`a401118SCIPMethod[OEIS`A401118ILP, Automatic],
       If[f === $Failed, None, OEIS`Private`a401118SCIPSolve[f, OEIS`A401118ILP]]]}],
  {True, True},
  TestID -> "automatic-picks-scip-when-found"
]

(* Plain calls go to the Method -> Automatic definitions: they reach a401118SCIPMethod, and A401118ILP.wl's own a401118ILPSet only when SCIP is missing *)

VerificationTest[
  {Block[{OEIS`Private`a401118SCIPMethod = (Throw["method"] &)}, Catch[OEIS`A401118ILP[12]]],
   Block[{OEIS`Private`a401118SCIPMethod = (Throw["method"] &)}, Catch[OEIS`A401118List[5]]]},
  {"method", "method"},
  TestID -> "plain-call-uses-automatic"
]

(* "LinearOptimization" runs the packages' own code: A401118ILP.wl's a401118ILPSet and A401118Incremental.wl's lcmTriangleMax *)

VerificationTest[
  {Block[{OEIS`Private`a401118ILPSet = (Throw["ilp"] &)}, Catch[OEIS`A401118ILP[12, Method -> "LinearOptimization"]]],
   Block[{OEIS`Private`lcmTriangleMax = (Throw["lo"] &)}, Catch[OEIS`A401118List[6, Method -> "LinearOptimization"]]]},
  {"ilp", "lo"},
  TestID -> "linearoptimization-uses-package-code"
]

(* When the SCIP library is built, Method -> "SCIP" must agree with the b-file and give valid subsets *)

VerificationTest[
  If[OEIS`Private`a401118SCIPFunction[] === $Failed, True,
    Module[{s = OEIS`LCMTriangleFreeSubset[120, Method -> "SCIP"],
            t = OEIS`Private`a401118SCIPILPSet[150, OEIS`Private`a401118SCIPMethod[OEIS`A401118ILP, "SCIP"]]},
      OEIS`A401118ILP /@ {6, 12, 73, 100} == {5, 10, 55, 76} &&
       OEIS`A401118List[73, Method -> "SCIP"][[{6, 12, 73}]] == {5, 10, 55} &&
       OEIS`A401118Incremental[150, Method -> "SCIP"] == 111 &&
       Length[s] == 88 && NoneTrue[OEIS`LCMTriangles[120], SubsetQ[s, #] &] &&
       Length[t] == 111 && NoneTrue[OEIS`LCMTriangles[150], SubsetQ[t, #] &]]],
  True,
  TestID -> "scip-if-built"
]

(* Without the library, Automatic falls back to LinearOptimization and "SCIP" is an error *)

VerificationTest[
  Block[{OEIS`Private`a401118SCIPFunction = ($Failed &)},
    {OEIS`Private`a401118SCIPMethod[OEIS`A401118ILP, Automatic], OEIS`A401118ILP[19], OEIS`A401118List[19],
     OEIS`A401118ILP[19, Method -> "SCIP"], OEIS`A401118Incremental[19, Method -> "SCIP"]}],
  {None, 16, {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16}, $Failed, $Failed},
  {OEIS`A401118ILP::noscip, OEIS`A401118Incremental::noscip},
  TestID -> "no-scip-fallback"
]

(* A401118.wl, the exhaustive search, is not touched *)

VerificationTest[Options[OEIS`A401118], {}, TestID -> "a401118-untouched"]


(* Invalid arguments *)

VerificationTest[OEIS`A401118ILP[12, Method -> "Gurobi"], $Failed, {OEIS`A401118ILP::method}, TestID -> "message-ilp-method"]
VerificationTest[OEIS`A401118ILP[0, Method -> "SCIP"], $Failed, {OEIS`A401118ILP::posint}, TestID -> "message-ilp-posint"]
VerificationTest[OEIS`A401118Incremental[12, Method -> 3], $Failed, {OEIS`A401118Incremental::method}, TestID -> "message-incremental-method"]
VerificationTest[OEIS`A401118List[0, Method -> "SCIP"], $Failed, {OEIS`A401118List::posint}, TestID -> "message-list-posint"]
