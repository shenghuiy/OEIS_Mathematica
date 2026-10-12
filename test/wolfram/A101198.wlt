(* Tests for src/wolfram/A101198.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A101198.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


(* Examples from docs/A101198.md *)

VerificationTest[OEIS`A101198[8], 3, TestID -> "example-a8"]

VerificationTest[
  Select[IntegerPartitions[8], First[#] - Length[#] == 1 &],
  {{5, 1, 1, 1}, {4, 3, 1}, {4, 2, 2}},
  TestID -> "example-a8-partitions"
]

VerificationTest[
  OEIS`PartitionRankCountList[1, 20],
  {0, 1, 0, 1, 1, 2, 1, 3, 3, 5, 5, 8, 8, 13, 14, 20, 23, 31, 35, 48},
  TestID -> "example-first-20"
]

VerificationTest[
  {OEIS`PartitionRankCount[3, 20], OEIS`PartitionRankCount[-3, 20]},
  {40, 40},
  TestID -> "example-rank-3"
]

VerificationTest[
  OEIS`A101198 /@ {100, 1000},
  {6203548, 245302742607816804169710132801},
  TestID -> "example-b-file"
]


(* The DATA sections of the OEIS entries for ranks 0 to 3, an independent source *)

VerificationTest[
  OEIS`PartitionRankCountList[1, 52],
  {0, 1, 0, 1, 1, 2, 1, 3, 3, 5, 5, 8, 8, 13, 14, 20, 23, 31, 35, 48, 55, 72, 84, 108, 126, 160, 187, 233, 275,
   340, 398, 489, 574, 697, 819, 988, 1158, 1390, 1627, 1941, 2271, 2696, 3145, 3721, 4335, 5104, 5938, 6967,
   8088, 9462, 10964, 12783},
  TestID -> "oeis-A101198-rank-1"
]

VerificationTest[
  OEIS`PartitionRankCountList[0, 55],
  {1, 0, 1, 1, 1, 1, 3, 2, 4, 4, 6, 7, 11, 11, 16, 19, 25, 29, 40, 45, 60, 70, 89, 105, 134, 156, 196, 232, 285,
   336, 414, 485, 591, 696, 839, 987, 1187, 1389, 1661, 1946, 2311, 2702, 3201, 3731, 4400, 5126, 6018, 6997,
   8195, 9502, 11093, 12849, 14949, 17281, 20062},
  TestID -> "oeis-A047993-rank-0"
]

VerificationTest[
  OEIS`PartitionRankCountList[2, 58],
  {0, 0, 1, 0, 1, 1, 2, 2, 3, 3, 6, 6, 9, 10, 15, 16, 23, 27, 36, 42, 55, 64, 84, 98, 124, 147, 185, 217, 270,
   318, 391, 461, 562, 661, 802, 942, 1132, 1331, 1592, 1864, 2220, 2597, 3077, 3593, 4240, 4940, 5811, 6758,
   7916, 9192, 10737, 12438, 14488, 16755, 19459, 22465, 26024, 29987},
  TestID -> "oeis-A101199-rank-2"
]

VerificationTest[
  OEIS`PartitionRankCountList[3, 58],
  {0, 0, 0, 1, 0, 1, 1, 2, 2, 4, 3, 6, 7, 10, 11, 17, 18, 26, 30, 40, 47, 63, 72, 94, 111, 140, 165, 209, 244,
   304, 359, 440, 519, 634, 743, 901, 1060, 1273, 1494, 1789, 2092, 2491, 2914, 3449, 4026, 4752, 5530, 6502,
   7561, 8852, 10272, 11997, 13889, 16171, 18695, 21700, 25041, 29002},
  TestID -> "oeis-A101200-rank-3"
]

(* Values from the b-file of A101198 (Seiichi Manyama, n = 1..10000) *)

VerificationTest[
  OEIS`PartitionRankCountList[1, 1000][[{100, 500, 1000}]],
  {6203548, 33231830399282058795, 245302742607816804169710132801},
  TestID -> "oeis-b-file-list"
]

VerificationTest[
  OEIS`A101198[500],
  33231830399282058795,
  TestID -> "oeis-b-file-single-term"
]


(* Against the definition. The number partitioned is j, not n: when all the test files run in one kernel,
   a Global`n made here would be shadowed by the OEIS`n that loading A399539.wl creates, and that
   package's load-package test fails on the message. *)

VerificationTest[
  Table[OEIS`PartitionRankCount[m, j], {m, -6, 6}, {j, 1, 24}],
  Table[Count[IntegerPartitions[j], p_ /; First[p] - Length[p] == m], {m, -6, 6}, {j, 1, 24}],
  TestID -> "brute-force"
]

VerificationTest[
  Table[OEIS`PartitionRankCountList[m, 300], {m, -3, 4}],
  Table[OEIS`PartitionRankCount[m, j], {m, -3, 4}, {j, 1, 300}],
  TestID -> "list-matches-single-terms"
]

(* Ranks run from 1 - j (all parts 1) to j - 1 (one part j) *)

VerificationTest[
  Table[Sum[OEIS`PartitionRankCount[m, j], {m, 1 - j, j - 1}], {j, 1, 60}],
  PartitionsP[Range[60]],
  TestID -> "ranks-sum-to-p"
]

VerificationTest[
  Table[{OEIS`PartitionRankCount[j - 1, j], OEIS`PartitionRankCount[j, j], OEIS`PartitionRankCount[1 - j, j]}, {j, 1, 12}],
  ConstantArray[{1, 0, 1}, 12],
  TestID -> "extreme-ranks"
]

VerificationTest[
  OEIS`PartitionRankCountList[7, 5],
  {0, 0, 0, 0, 0},
  TestID -> "list-rank-beyond-nmax"
]

(* Summing (2.12) over m >= 2 telescopes to Sum (-1)^(k+1) p(n - 3k(k+1)/2), the Hopkins-Sellers count
   of the Garden of Eden partitions (rank <= -2) in docs/BulgarianSolitaire.md *)

VerificationTest[
  Table[Sum[OEIS`PartitionRankCount[m, j], {m, 2, j}], {j, 1, 60}],
  Table[Sum[(-1)^(k + 1) PartitionsP[j - 3 k (k + 1)/2], {k, 1, j}], {j, 1, 60}],
  TestID -> "rank-at-least-2-hopkins-sellers"
]


(* Invalid arguments: a message and $Failed *)

VerificationTest[OEIS`A101198[0], $Failed, {OEIS`A101198::posint}, TestID -> "a-zero-message"]
VerificationTest[OEIS`A101198[2.5], $Failed, {OEIS`A101198::posint}, TestID -> "a-real-message"]
VerificationTest[
  OEIS`PartitionRankCount[1/2, 5], $Failed, {OEIS`PartitionRankCount::int},
  TestID -> "count-rank-not-integer-message"
]
VerificationTest[
  OEIS`PartitionRankCount[1, -3], $Failed, {OEIS`PartitionRankCount::posint},
  TestID -> "count-n-negative-message"
]
VerificationTest[
  OEIS`PartitionRankCountList[1, 0], $Failed, {OEIS`PartitionRankCountList::posint},
  TestID -> "list-nmax-zero-message"
]
VerificationTest[
  OEIS`PartitionRankCountList[x, 5], $Failed, {OEIS`PartitionRankCountList::int},
  TestID -> "list-rank-symbolic-message"
]
