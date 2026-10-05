(* Tests for src/wolfram/EulerPhiInverse.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "EulerPhiInverse.wl"}]];
  (* phi(x) = n forces x < 30 n for n <= 4000, so a table up to 120000 covers every solution *)
  ref = GroupBy[Transpose[{Range[120000], EulerPhi[Range[120000]]}], Last -> First];
  True,
  True,
  TestID -> "load-package"
]


(* Known values *)

VerificationTest[OEIS`EulerPhiInverse[24], {35, 39, 45, 52, 56, 70, 72, 78, 84, 90}, TestID -> "phi-inverse-24"]
VerificationTest[OEIS`EulerPhiInverse[12], {13, 21, 26, 28, 36, 42}, TestID -> "phi-inverse-12"]
VerificationTest[OEIS`EulerPhiInverse[2], {3, 4, 6}, TestID -> "phi-inverse-2"]
VerificationTest[OEIS`EulerPhiInverse[1], {1, 2}, TestID -> "phi-inverse-1"]
VerificationTest[OEIS`EulerPhiInverse[14], {}, TestID -> "phi-inverse-no-solution"]
VerificationTest[OEIS`EulerPhiInverse[3], {}, TestID -> "phi-inverse-odd"]


(* Agreement with a table of EulerPhi, including the empty case *)

VerificationTest[
  AllTrue[Range[4000], OEIS`EulerPhiInverse[#] === Lookup[ref, #, {}] &],
  True,
  TestID -> "phi-inverse-vs-table"
]


(* More solutions than the initial bound of 1024, so the bound is doubled: every x is a solution and the list is sorted *)

VerificationTest[
  Module[{n = 2^20 3^5 5^2 7, s},
    s = OEIS`EulerPhiInverse[n];
    {Length[s] > 1024, s === Union[s], AllTrue[s, EulerPhi[#] == n &]}],
  {True, True, True},
  TestID -> "bound-doubling"
]
