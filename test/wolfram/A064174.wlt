(* Tests for src/wolfram/A064174.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A064174.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


(* Examples from docs/A064174.md *)

VerificationTest[A064174[8], 12, TestID -> "example-a8"]

VerificationTest[
  Select[IntegerPartitions[8], First[#] >= Length[#] &],
  {{8}, {7, 1}, {6, 2}, {6, 1, 1}, {5, 3}, {5, 2, 1}, {5, 1, 1, 1}, {4, 4}, {4, 3, 1}, {4, 2, 2}, {4, 2, 1, 1},
   {3, 3, 2}},
  TestID -> "example-a8-partitions"
]

VerificationTest[
  {A064174[20], PartitionsP[19] - PartitionsP[15] + PartitionsP[8]},
  {336, 336},
  TestID -> "example-a20"
]

VerificationTest[
  A064174List[20],
  {1, 1, 2, 3, 4, 6, 9, 12, 17, 23, 31, 42, 56, 73, 96, 125, 161, 207, 265, 336},
  TestID -> "example-first-20"
]

VerificationTest[
  A064174 /@ {100, 1000},
  {98399016, 12153435997907041976361053286977},
  TestID -> "example-b-file"
]


(* The DATA section of the OEIS entry, an independent source *)

VerificationTest[
  A064174List[48],
  {1, 1, 2, 3, 4, 6, 9, 12, 17, 23, 31, 42, 56, 73, 96, 125, 161, 207, 265, 336, 426, 536, 672, 840, 1046, 1296,
   1603, 1975, 2425, 2970, 3628, 4417, 5367, 6503, 7861, 9482, 11412, 13702, 16423, 19642, 23447, 27938, 33231,
   39453, 46767, 55342, 65386, 77135},
  TestID -> "oeis-data"
]

(* Values from the b-file (Seiichi Manyama, n = 1..10000) *)

VerificationTest[
  A064174List[5000][[{100, 500, 1000, 5000}]],
  {98399016, 1166712196694213453355, 12153435997907041976361053286977,
   85296110092475145438547781834554295747480164465559486418756191304666615733},
  TestID -> "oeis-b-file-list"
]

VerificationTest[
  A064174[10000],
  18141714859717844207459017801576123796093284728017352217783686031676660987880752749768399136979516035258372,
  TestID -> "oeis-b-file-single-term"
]


(* Against the definition, and both descriptions in the OEIS comments *)

VerificationTest[
  A064174List[30],
  Table[Count[IntegerPartitions[n], p_ /; First[p] >= Length[p]], {n, 1, 30}],
  TestID -> "brute-force"
]

VerificationTest[
  Table[Count[IntegerPartitions[n], p_ /; First[p] <= Length[p]], {n, 1, 30}],
  A064174List[30],
  TestID -> "brute-force-conjugate"
]

VerificationTest[
  Table[Count[IntegerPartitions[n], p_ /; MemberQ[p, Max[First[p], Length[p]]]], {n, 1, 30}],
  A064174List[30],
  TestID -> "brute-force-kimberling"
]

(* The list (recurrence) against single terms (sum of partition numbers) *)

VerificationTest[
  A064174List[600],
  A064174 /@ Range[600],
  TestID -> "list-matches-single-terms"
]


(* Relations with the other rank counts *)

(* The other pentagonal numbers give the negative ranks, A064173 *)
VerificationTest[
  PartitionsP[Range[200]] - A064174List[200],
  Table[Sum[(-1)^(k - 1) PartitionsP[n - k (3 k + 1)/2], {k, 1, n}], {n, 1, 200}],
  TestID -> "complement-A064173"
]

VerificationTest[
  PartitionsP[Range[24]] - A064174List[24],
  Table[Count[IntegerPartitions[n], p_ /; First[p] < Length[p]], {n, 1, 24}],
  TestID -> "complement-A064173-brute-force"
]

(* a(n) = (p(n) + N(0, n))/2, by conjugation; A047993 is N(0, n) *)
VerificationTest[
  2 A064174List[200] - PartitionsP[Range[200]],
  Table[Sum[(-1)^(k - 1) (PartitionsP[n - k (3 k - 1)/2] - PartitionsP[n - k (3 k + 1)/2]), {k, 1, n}], {n, 1, 200}],
  TestID -> "rank-zero-A047993"
]

VerificationTest[
  (2 A064174List[55] - PartitionsP[Range[55]]),
  {1, 0, 1, 1, 1, 1, 3, 2, 4, 4, 6, 7, 11, 11, 16, 19, 25, 29, 40, 45, 60, 70, 89, 105, 134, 156, 196, 232, 285,
   336, 414, 485, 591, 696, 839, 987, 1187, 1389, 1661, 1946, 2311, 2702, 3201, 3731, 4400, 5126, 6018, 6997,
   8195, 9502, 11093, 12849, 14949, 17281, 20062},
  TestID -> "rank-zero-oeis-A047993"
]


(* The generating function *)

VerificationTest[
  Rest[CoefficientList[
    Series[Sum[(-1)^(k - 1) x^(k (3 k - 1)/2), {k, 1, 8}]/Product[1 - x^r, {r, 1, 80}], {x, 0, 80}], x]],
  A064174List[80],
  TestID -> "generating-function"
]

(* Paul D. Hanna's generating function from the OEIS entry *)
VerificationTest[
  Rest[CoefficientList[
    Normal[Series[Sum[x^m Product[(1 - x^(m + k - 1))/(1 - x^k), {k, 1, m}], {m, 1, 40}], {x, 0, 40}]], x]],
  A064174List[40],
  TestID -> "generating-function-hanna"
]


(* The asymptotic a(n) ~ e^(Pi Sqrt[2n/3])/(8 Sqrt[3] n) (1 + c/Sqrt[n]), c = 5 Pi/(24 Sqrt[6]) - Sqrt[6]/(2 Pi) *)

VerificationTest[
  Module[{c = 5 Pi/(24 Sqrt[6]) - Sqrt[6]/(2 Pi), lead},
    lead[n_] := Exp[Pi Sqrt[2 n/3]]/(8 Sqrt[3] n);
    {Abs[N[A064174[10000]/lead[10000], 30] - 1] < 0.002,
     Abs[N[Sqrt[10000] (A064174[10000]/lead[10000] - 1) - c, 30]] < 0.001}],
  {True, True},
  TestID -> "asymptotic"
]


(* Invalid arguments: a message and $Failed *)

VerificationTest[A064174[0], $Failed, {A064174::posint}, TestID -> "a-zero-message"]
VerificationTest[A064174[2.5], $Failed, {A064174::posint}, TestID -> "a-real-message"]
VerificationTest[A064174List[-1], $Failed, {A064174List::posint}, TestID -> "list-negative-message"]
VerificationTest[A064174List[x], $Failed, {A064174List::posint}, TestID -> "list-symbolic-message"]
