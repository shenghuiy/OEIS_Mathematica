(* Tests for src/wolfram/A399539.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A399539.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


(* First terms: k such that psi(k) - phi(k) = d(k)^4 *)

VerificationTest[
  OEIS`A399539[40000],
  {2071, 3007, 4087, 14780, 17468, 18428, 19388, 39288},
  TestID -> "first-terms"
]

(* The limit is inclusive *)

VerificationTest[OEIS`A399539[2070], {}, TestID -> "limit-exclusive-below"]
VerificationTest[OEIS`A399539[2071], {2071}, TestID -> "limit-inclusive"]

(* 10^5 spans two sieve blocks of 2^16 *)

VerificationTest[
  OEIS`A399539[10^5],
  {2071, 3007, 4087, 14780, 17468, 18428, 19388, 39288},
  TestID -> "across-block-boundary"
]

(* Independent check from the definition, psi(k) = k Prod(1 + 1/p) *)

VerificationTest[
  Module[{psi, phi},
    psi[k_] := If[k == 1, 1, k Times @@ (1 + 1/First /@ FactorInteger[k])];
    phi = EulerPhi;
    OEIS`A399539[10^5] === Select[Range[10^5], psi[#] - phi[#] == DivisorSigma[0, #]^4 &]],
  True,
  TestID -> "vs-definition"
]

(* 1 satisfies psi - phi = 0 != d(1)^4 = 1 *)

VerificationTest[MemberQ[OEIS`A399539[1000], 1], False, TestID -> "one-excluded"]


(* Examples from docs/A399539.md *)

VerificationTest[OEIS`A399539[10^4], {2071, 3007, 4087}, TestID -> "example-10^4"]

VerificationTest[
  OEIS`A399539[10^6],
  Select[Range[10^6], # > 1 && DivisorSigma[0, #]^4 == # Times @@ (1 + 1/First /@ FactorInteger[#]) - EulerPhi[#] &],
  TestID -> "example-10^6-vs-select"
]

(* The result does not depend on the block size *)

VerificationTest[OEIS`isokSeg[10^6, 2^10], OEIS`isokSeg[10^6, 2^16], TestID -> "example-block-size-2^10"]
VerificationTest[
  AllTrue[{7, 1000}, OEIS`isokSeg[10^5, #] === OEIS`isokSeg[10^5, 2^16] &],
  True,
  TestID -> "example-block-sizes-7-1000"
]

VerificationTest[
  OEIS`A399539[10^8],
  {2071, 3007, 4087, 14780, 17468, 18428, 19388, 39288, 114160, 193340,
   263252, 628608, 755325, 976284, 2823876, 3133344, 3182328, 3392260,
   3549105, 3556196, 4488544, 5065092, 5277051, 7176924, 8791600, 9928704,
   10794375, 12330540, 20254976, 21778944, 35991872, 38026716, 38637144,
   39080960, 40434636, 43918956, 45348384, 50917248, 53308125, 54561364,
   68134912, 73605120, 82462800, 88654800, 92143980},
  TestID -> "example-10^8-45-terms"
]
