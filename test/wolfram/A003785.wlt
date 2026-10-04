(* Tests for src/wolfram/A003785.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A003785.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


(* etaSeries[k, nn] = Prod_{m>=1} (1 - x^(k m)) truncated after x^nn *)

VerificationTest[
  Expand[OEIS`etaSeries[1, 6]],
  Expand[1 - OEIS`Private`x - OEIS`Private`x^2 + OEIS`Private`x^5],   (* Euler's pentagonal number theorem *)
  TestID -> "eta-series-pentagonal"
]

VerificationTest[
  Expand[OEIS`etaSeries[2, 6]],
  Expand[1 - OEIS`Private`x^2 - OEIS`Private`x^4],
  TestID -> "eta-series-k2"
]

VerificationTest[
  AllTrue[Tuples[{{1, 2, 3, 4, 7}, {0, 1, 5, 12, 20}}],
    Function[{kn},
      Module[{k = kn[[1]], nn = kn[[2]], x = OEIS`Private`x},
        Expand[OEIS`etaSeries[k, nn]] ===
          Expand[Normal @ Series[Product[1 - x^(k m), {m, 1, Max[nn, 1]}], {x, 0, nn}]]]]],
  True,
  TestID -> "eta-series-vs-product"
]

VerificationTest[OEIS`etaSeries[3, 0], 1, TestID -> "eta-series-nn-zero"]


(* A003785 *)

VerificationTest[Array[OEIS`A003785, 3, 0], {0, 0, 0}, TestID -> "zero-below-3"]
VerificationTest[OEIS`A003785[-5], 0, TestID -> "negative-argument"]

VerificationTest[
  Array[OEIS`A003785, 10, 3],
  {1, 10, 0, 0, -88, -132, 0, 0, 1275, 736},
  TestID -> "regression-terms"
]


(* Examples from docs/A003785.md: a(1) to a(20), computed independently in Python *)

VerificationTest[
  Array[OEIS`A003785, 20],
  {0, 0, 1, 10, 0, 0, -88, -132, 0, 0, 1275, 736, 0, 0, -8040, -2880, 0, 0, 24035, 13080},
  TestID -> "example-a1-to-a20"
]
