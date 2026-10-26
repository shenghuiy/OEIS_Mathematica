(* Tests for src/wolfram/A400000.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A400000.wl"}]];
  True,
  True,
  TestID -> "load-package"
]

(* Only A400000 is public; the compiled kernel stays in OEIS`Private` *)

VerificationTest[
  NameQ /@ {"OEIS`n", "OEIS`a400000Pruned", "OEIS`Private`a400000Pruned"},
  {False, False, True},
  TestID -> "only-A400000-public"
]


(* The first 120 terms of the b-file (Eric Fox, n = 1..10000) *)

VerificationTest[
  OEIS`A400000[120],
  {0, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 3, 1, 2, 1, 10, 1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
   1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 11, 1, 2, 2, 3, 2, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
   1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 11, 1, 2, 2, 3, 2, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
   1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 19, 1, 2, 2, 3, 2, 3, 2, 4},
  TestID -> "b-file-first-120"
]

(* All 10000 b-file terms, compared by SHA-256 of the list so the file needs no network access *)

VerificationTest[
  Hash[OEIS`A400000[10000], "SHA256", "HexString"],
  "1bd12b74661b611c1b8fc4484876873bfbee2cb120b2613fa458a245f9094153",
  TestID -> "b-file-10000-hash"
]

(* Independent check from the definition: exact rational line-of-sight tests, no slopes or pruning *)

VerificationTest[
  Module[{seesQ, visible, next},
    seesQ[a_, n_, h_, i_] := AllTrue[Range[i + 1, n - 1], a[[#]] <= a[[i]] + (h - a[[i]]) (# - i)/(n - i) &];
    visible[a_, h_] := Count[Range[Length[a]], i_ /; seesQ[a, Length[a] + 1, h, i]];
    next[a_] := Append[a, NestWhile[# + 1 &, 0, visible[a, #] != # &]];
    Nest[next, {}, 200] === OEIS`A400000[200]],
  True,
  TestID -> "vs-definition-200"
]

(* A prefix of a longer run is the shorter run *)

VerificationTest[
  Take[OEIS`A400000[5000], 1234] === OEIS`A400000[1234],
  True,
  TestID -> "prefix-consistent"
]

(* Every term h of a(1..n) sees exactly h earlier buildings, and no smaller height sees exactly its own height (n = 1000) *)

VerificationTest[
  Module[{a = OEIS`A400000[1000], count},
    count[n_, h_] := Module[{c = 0, dx0 = 0, dy0 = 0, dy},
      Do[dy = a[[n - dx]] - h; If[dx0 dy >= dx dy0, c++; dx0 = dx; dy0 = dy], {dx, 1, n - 1}]; c];
    AllTrue[Range[1000], count[#, a[[#]]] == a[[#]] && AllTrue[Range[0, a[[#]] - 1], Function[h, count[#, h] != h]] &]],
  True,
  TestID -> "each-term-minimal"
]

(* Arguments that are not positive integers stay unevaluated *)

VerificationTest[OEIS`A400000[0], OEIS`A400000[0], TestID -> "zero-unevaluated"]
VerificationTest[OEIS`A400000[2.5], OEIS`A400000[2.5], TestID -> "real-unevaluated"]


(* Examples from docs/A400000.md *)

VerificationTest[OEIS`A400000[20], {0, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 3, 1, 2, 1, 10, 1, 2, 2, 3}, TestID -> "example-first-20"]

VerificationTest[
  Part[OEIS`A400000[112], 16 Range[7]],
  {10, 10, 11, 10, 11, 10, 19},
  TestID -> "example-spikes-16k"
]

VerificationTest[
  Module[{a = OEIS`A400000[10^6]}, {Max[a], First@FirstPosition[a, Max[a]], Total[a], Count[a, 1]}],
  {372, 827154, 2931483, 311609},
  TestID -> "example-10^6"
]

(* Record heights and where they occur, against A399949 and A399950 (records up to n = 2400000, about 5 s) *)

VerificationTest[
  Module[{a = OEIS`A400000[2400000], m = -1, rec = {}},
    Do[If[a[[i]] > m, m = a[[i]]; AppendTo[rec, {m, i}]], {i, Length[a]}];
    rec],
  Transpose[{
    {0, 1, 2, 3, 10, 11, 19, 20, 21, 111, 148, 165, 355, 357, 367, 372, 378, 401},
    {1, 2, 4, 8, 16, 48, 112, 282, 622, 1246, 2721, 3984, 61898, 129103, 342163, 827154, 1278296, 2325733}}],
  TestID -> "example-records-A399949-A399950"
]
