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


(* A case with many solutions (220281), all valid and sorted *)

VerificationTest[
  Module[{n = 2^20 3^5 5^2 7, s},
    s = OEIS`EulerPhiInverse[n];
    {Length[s], s === Union[s], AllTrue[s, EulerPhi[#] == n &]}],
  {220281, True, True},
  TestID -> "many-solutions"
]


(* Even n with no solution, and a large odd n, which is answered without compiling anything.
   For n = 2 (2^31 - 1) the only primes q with q - 1 | n are 2 and 3, and EulerPhi[2^a 3^b] is never 2 p for an odd prime p. *)

VerificationTest[OEIS`EulerPhiInverse[2 (2^31 - 1)], {}, TestID -> "large-even-no-solution"]
VerificationTest[OEIS`EulerPhiInverse[3^35], {}, TestID -> "large-odd"]


(* The Integer64 and Integer128 kernels give the same solutions *)

VerificationTest[
  AllTrue[{2, 24, 720720, 2^10 3^4 5^2 7 11 13, 2^20 3^5 5^2 7},
    Sort[Rest[OEIS`Private`searchKernel["Integer64"][#]]] === Sort[Rest[OEIS`Private`searchKernel["Integer128"][#]]] &],
  True,
  TestID -> "int64-vs-int128"
]


(* n >= 2^58 uses the Integer128 kernel: the solutions include x0 and all satisfy phi(x) = n *)

VerificationTest[
  Module[{x0 = 2^61 3^2 5, n, s},
    n = EulerPhi[x0];
    s = OEIS`EulerPhiInverse[n];
    {n >= 2^58, MemberQ[s, x0], s === Union[s], AllTrue[s, EulerPhi[#] == n &]}],
  {True, True, True, True},
  TestID -> "large-n-int128"
]
