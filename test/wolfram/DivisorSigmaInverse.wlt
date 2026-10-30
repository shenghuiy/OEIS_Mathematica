(* Tests for src/wolfram/DivisorSigmaInverse.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "DivisorSigmaInverse.wl"}]];
  brute[n_, k_] := Select[Range[n], DivisorSigma[k, #] == n &];
  True,
  True,
  TestID -> "load-package"
]


(* Known values *)

VerificationTest[DivisorSigmaInverse[24], {14, 15, 23}, TestID -> "sigma-inverse-24"]
VerificationTest[DivisorSigmaInverse[1], {1}, TestID -> "sigma-inverse-1"]
VerificationTest[DivisorSigmaInverse[1, 2], {1}, TestID -> "sigma-inverse-1-k2"]
VerificationTest[DivisorSigmaInverse[2], {}, TestID -> "sigma-inverse-no-solution"]
VerificationTest[DivisorSigmaInverse[30, 2], {}, TestID -> "sigma2-inverse-no-solution"]
VerificationTest[invSigmaDivisors[12], {{1}, {}, {2}, {3}, {5}, {6, 11}}, TestID -> "inv-sigma-divisors-12"]
VerificationTest[invSigmaDivisors[1], {{1}}, TestID -> "inv-sigma-divisors-1"]


(* The bound u keeps only solutions x <= u *)

VerificationTest[DivisorSigmaInverse[60, 1, 40], {24, 38}, TestID -> "bound-u"]
VerificationTest[DivisorSigmaInverse[48, 1, 20], {}, TestID -> "bound-u-empty"]
VerificationTest[invSigmaDivisors[12, 1, 5], {{1}, {}, {2}, {3}, {5}, {}}, TestID -> "inv-sigma-divisors-bound-u"]


(* Agreement with brute force: x <= sigma_k(x), so x <= n suffices *)

VerificationTest[
  AllTrue[Range[300], Function[n, AllTrue[{1, 2, 3}, DivisorSigmaInverse[n, #] === brute[n, #] &]]],
  True,
  TestID -> "sigma-inverse-vs-brute-force"
]

VerificationTest[
  AllTrue[Range[120], Function[n, AllTrue[{1, 2},
    Function[k, invSigmaDivisors[n, k] === (brute[#, k] & /@ Divisors[n])]]]],
  True,
  TestID -> "inv-sigma-divisors-vs-brute-force"
]


(* Compiled DP agrees with the association-based fallback used for n >= 2^62 *)

VerificationTest[
  AllTrue[Range[80], invSigmaDivisors[#] === OEIS`Private`invSigmaDivisorsInterpreted[#, 1, Infinity] &],
  True,
  TestID -> "compiled-vs-interpreted"
]


(* n >= 2^62 takes the interpreted path: 2^62 is the only solution of sigma(x) = 2^63 - 1 *)

VerificationTest[DivisorSigmaInverse[2^63 - 1], {2^62}, TestID -> "large-n-interpreted"]

VerificationTest[
  Last[invSigmaDivisors[2^63 - 1]],
  {2^62},
  TestID -> "large-n-inv-sigma-divisors"
]


(* Examples from docs/DivisorSigmaInverse.md *)

VerificationTest[DivisorSigmaInverse[12], {6, 11}, TestID -> "example-12"]
VerificationTest[DivisorSigmaInverse[24], {14, 15, 23}, TestID -> "example-24"]
VerificationTest[DivisorSigmaInverse[31], {16, 25}, TestID -> "example-31"]
VerificationTest[DivisorSigmaInverse[10], {}, TestID -> "example-10-no-solution"]
VerificationTest[DivisorSigmaInverse[50, 2], {6, 7}, TestID -> "example-50-k2"]
VerificationTest[DivisorSigmaInverse[24, 1, 20], {14, 15}, TestID -> "example-24-bound-20"]
VerificationTest[
  invSigmaDivisors[12],
  {{1}, {}, {2}, {3}, {5}, {6, 11}},
  TestID -> "example-inv-sigma-divisors-12"
]

VerificationTest[
  AllTrue[Tuples[{Range[60], {1, 2}}],
    Function[{nk}, With[{n = nk[[1]], k = nk[[2]]},
      DivisorSigmaInverse[n, k] === Select[Range[n^(k + 1) + 1], DivisorSigma[k, #] == n &]]]],
  True,
  TestID -> "example-brute-force-n1-60"
]

VerificationTest[Length[DivisorSigmaInverse[10!]], 1195, TestID -> "example-10-factorial"]
VerificationTest[DivisorSigmaInverse[1000], {}, TestID -> "example-1000-no-solution"]


(* dpCompiled with countOnly True returns the solution count as the single row {count, 0} *)

VerificationTest[
  countOnly[n_, k_] := Module[{groups = OEIS`Private`cookSigma[n, k]},
    OEIS`Private`dpCompiled[n, n,
      Developer`ToPackedArray[Divisors[n], Integer],
      Developer`ToPackedArray[Flatten[groups[[All, All, 1]]], Integer],
      Developer`ToPackedArray[Flatten[groups[[All, All, 2]]], Integer],
      Developer`ToPackedArray[Prepend[1 + Accumulate[Length /@ groups], 1], Integer],
      0, True]];
  countOnly[24, 1],
  {{3, 0}},
  TestID -> "count-only-24"
]

VerificationTest[
  And @@ Flatten[Table[
    countOnly[n, k][[1, 1]] === Length[DivisorSigmaInverse[n, k]],
    {k, 1, 3}, {n, 2, 500}]],
  True,
  TestID -> "count-only-matches-length"
]


(* DivisorSigmaInverseCount agrees with the length of DivisorSigmaInverse *)

VerificationTest[DivisorSigmaInverseCount[24], 3, TestID -> "count-24"]
VerificationTest[DivisorSigmaInverseCount[1], 1, TestID -> "count-1"]
VerificationTest[DivisorSigmaInverseCount[2], 0, TestID -> "count-no-solution"]
VerificationTest[DivisorSigmaInverseCount[60, 1, 40], 2, TestID -> "count-bound-u"]
VerificationTest[
  And @@ Flatten[Table[
    DivisorSigmaInverseCount[n, k] === Length[DivisorSigmaInverse[n, k]],
    {k, 1, 3}, {n, 1, 500}]],
  True,
  TestID -> "count-matches-length"
]
VerificationTest[
  DivisorSigmaInverseCount[DivisorSigma[1, 2^70 + 1]] === Length[DivisorSigmaInverse[DivisorSigma[1, 2^70 + 1]]],
  True,
  TestID -> "count-large-n-fallback"
]
