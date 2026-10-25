(* Tests for src/wolfram/A401118_SCIP.wl. The SCIP cases pass trivially when src/c/a401118_scip/lib has no library. *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A401118_SCIP.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* No new public names: the Method option goes on A401118Incremental.wl's functions, the helpers stay in OEIS`Private`.
   Names["OEIS`*"] also holds the other packages' names when the whole suite runs in one kernel, so check by name. *)

VerificationTest[
  NameQ /@ {"OEIS`f", "OEIS`head", "OEIS`method", "OEIS`opts", "OEIS`a401118Solver", "OEIS`lcmTriangleMaxSCIP", "OEIS`a401118SCIPFunction",
    "OEIS`Private`a401118Solver", "OEIS`Private`lcmTriangleMaxSCIP", "OEIS`Private`a401118SCIPFunction"},
  {False, False, False, False, False, False, False, True, True, True},
  TestID -> "only-documented-public"
]

VerificationTest[
  Options /@ {OEIS`A401118Incremental, OEIS`A401118List, OEIS`LCMTriangleFreeSubset},
  ConstantArray[{Method -> Automatic}, 3],
  TestID -> "method-option-defined"
]


(* Examples from docs/A401118_SCIP.md *)

VerificationTest[
  OEIS`A401118List[150, Method -> "LinearOptimization"] === OEIS`A401118List[150, Method -> Automatic],
  True,
  TestID -> "example-methods-agree-150"
]

VerificationTest[
  With[{f = OEIS`Private`a401118SCIPFunction[]},
    {f === $Failed || Head[f] === ForeignFunction,
     MatchQ[OEIS`Private`a401118Solver[OEIS`A401118Incremental, Automatic],
       If[f === $Failed, OEIS`Private`lcmTriangleMax, OEIS`Private`lcmTriangleMaxSCIP[f]]]}],
  {True, True},
  TestID -> "automatic-picks-scip-when-found"
]

(* Calls without options go through a401118DefaultSolver, which this package sets to the Automatic choice *)

VerificationTest[
  {Block[{OEIS`Private`a401118DefaultSolver = (Throw["default"] &)}, Catch[OEIS`A401118List[5]]],
   OEIS`Private`a401118DefaultSolver[OEIS`A401118Incremental] === OEIS`Private`a401118Solver[OEIS`A401118Incremental, Automatic]},
  {"default", True},
  TestID -> "plain-call-uses-automatic"
]

(* When the SCIP library is built, Method -> "SCIP" must agree with the b-file and give a valid witness *)

VerificationTest[
  If[OEIS`Private`a401118SCIPFunction[] === $Failed, True,
    Module[{s = OEIS`LCMTriangleFreeSubset[120, Method -> "SCIP"]},
      OEIS`A401118List[73, Method -> "SCIP"][[{6, 12, 73}]] == {5, 10, 55} &&
       OEIS`A401118Incremental[150, Method -> "SCIP"] == 111 &&
       Length[s] == 88 && NoneTrue[OEIS`LCMTriangles[120], SubsetQ[s, #] &]]],
  True,
  TestID -> "scip-if-built"
]

(* Without the library, Automatic falls back to LinearOptimization and "SCIP" is an error *)

VerificationTest[
  Block[{OEIS`Private`a401118SCIPFunction = ($Failed &)},
    {OEIS`Private`a401118Solver[OEIS`A401118Incremental, Automatic], OEIS`A401118List[20], OEIS`A401118Incremental[20, Method -> "SCIP"]}],
  {OEIS`Private`lcmTriangleMax, {1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10, 10, 11, 12, 12, 13, 14, 15, 16, 16}, $Failed},
  {OEIS`A401118Incremental::noscip},
  TestID -> "no-scip-fallback"
]


(* Invalid arguments *)

VerificationTest[OEIS`A401118Incremental[12, Method -> "Gurobi"], $Failed, {OEIS`A401118Incremental::method}, TestID -> "message-method"]
VerificationTest[OEIS`A401118List[0, Method -> "SCIP"], $Failed, {OEIS`A401118List::posint}, TestID -> "message-posint-with-method"]
VerificationTest[
  OEIS`LCMTriangleFreeSubset[5, Method -> 3],
  $Failed,
  {OEIS`LCMTriangleFreeSubset::method},
  TestID -> "message-subset-method"
]
