(* Tests for src/wolfram/BulgarianSolitaire.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "BulgarianSolitaire.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


(* The move: examples from Hopkins, 30 Years of Bulgarian Solitaire *)

VerificationTest[BulgarianSolitaireStep[{6, 4, 3, 1, 1}], {5, 5, 3, 2}, TestID -> "step-example"]
VerificationTest[BulgarianSolitaireStep[{3, 2, 1}], {3, 2, 1}, TestID -> "step-fixed-point"]
VerificationTest[BulgarianSolitaireStep[{4, 2, 2}], {3, 3, 1, 1}, TestID -> "step-cycle-8-a"]
VerificationTest[BulgarianSolitaireStep[{3, 3, 1, 1}], {4, 2, 2}, TestID -> "step-cycle-8-b"]
VerificationTest[BulgarianSolitaireStep[{6}], {5, 1}, TestID -> "step-one-pile"]

(* A move keeps the number of cards *)

VerificationTest[
  AllTrue[Flatten[IntegerPartitions /@ Range[1, 12], 1],
    Total[BulgarianSolitaireStep[#]] == Total[#] && OEIS`Private`bsPartitionQ[BulgarianSolitaireStep[#]] &],
  True,
  TestID -> "step-preserves-sum"
]

(* Arguments that are not partitions give a message and $Failed *)

VerificationTest[BulgarianSolitaireStep[{1, 2}], $Failed, {BulgarianSolitaireStep::partition}, TestID -> "not-a-partition-message"]
VerificationTest[BulgarianSolitaireStep[{}], $Failed, {BulgarianSolitaireStep::partition}, TestID -> "empty-message"]
VerificationTest[BulgarianSolitaireStep[{3, 0}], $Failed, {BulgarianSolitaireStep::partition}, TestID -> "nonpositive-part-message"]
VerificationTest[BulgarianSolitaireStep[5], $Failed, {BulgarianSolitaireStep::partition}, TestID -> "integer-message"]
VerificationTest[
  Quiet[
    (#[{1, 2}] & /@ {BulgarianSolitaireStep, BulgarianSolitaireOrbit, BulgarianSolitaireCycle,
       BulgarianSolitaireDistance, BulgarianSolitairePeriodicQ, BulgarianSolitaireGardenOfEdenQ,
       BulgarianSolitairePreimages, BulgarianSolitaireRowMoves, BulgarianSolitaireBasinLevelSizes,
       BulgarianSolitaireComponent, BulgarianSolitaireReversedTree}),
    {BulgarianSolitaireStep::partition, BulgarianSolitaireOrbit::partition, BulgarianSolitaireCycle::partition,
     BulgarianSolitaireDistance::partition, BulgarianSolitairePeriodicQ::partition,
     BulgarianSolitaireGardenOfEdenQ::partition, BulgarianSolitairePreimages::partition,
     BulgarianSolitaireRowMoves::partition, BulgarianSolitaireBasinLevelSizes::partition,
     BulgarianSolitaireComponent::partition, BulgarianSolitaireReversedTree::partition}],
  ConstantArray[$Failed, 11],
  TestID -> "all-partition-functions-fail"
]
VerificationTest[
  BulgarianSolitaireReversedTree[{1, 2}, VertexLabels -> "Name"], $Failed,
  {BulgarianSolitaireReversedTree::partition}, TestID -> "reversed-tree-with-options-message"
]
VerificationTest[
  StringContainsQ[ToString[BulgarianSolitaireStep::partition], "not a partition"], True,
  TestID -> "message-text"
]


(* Orbit, cycle, distance: the 15-card game in the article *)

VerificationTest[
  BulgarianSolitaireOrbit[{6, 4, 3, 1, 1}],
  {{6, 4, 3, 1, 1}, {5, 5, 3, 2}, {4, 4, 4, 2, 1}, {5, 3, 3, 3, 1}, {5, 4, 2, 2, 2}, {5, 4, 3, 1, 1, 1}, {6, 4, 3, 2}, {5, 4, 3, 2, 1}},
  TestID -> "orbit-15-cards"
]
VerificationTest[BulgarianSolitaireCycle[{6, 4, 3, 1, 1}], {{5, 4, 3, 2, 1}}, TestID -> "cycle-15-cards"]
VerificationTest[BulgarianSolitaireDistance[{6, 4, 3, 1, 1}], 7, TestID -> "distance-15-cards"]

(* The partitions of 8 have two cycles; (4, 3, 1) is on the one of length 4 *)

VerificationTest[
  Sort[BulgarianSolitaireCycle[{4, 3, 1}]],
  Sort[{{4, 3, 1}, {3, 3, 2}, {3, 2, 2, 1}, {4, 2, 1, 1}}],
  TestID -> "cycle-8-four-cycle"
]
VerificationTest[BulgarianSolitaireDistance[{4, 3, 1}], 0, TestID -> "distance-on-cycle"]

(* Eriksson-Jonsson, Figure 1: (3, 3, 2, 1, 1) takes 12 = k(k - 1) moves to the staircase for k = 4 *)

VerificationTest[BulgarianSolitaireDistance[{3, 3, 2, 1, 1}], 12, TestID -> "distance-figure-1"]

(* Igusa: the partition (k-1, k-1, k-2, ..., 2, 1, 1) is k(k - 1) moves from the staircase *)

VerificationTest[
  Table[
    BulgarianSolitaireDistance[Join[{k - 1, k - 1}, Range[k - 2, 1, -1], {1}]],
    {k, 3, 8}],
  Table[k (k - 1), {k, 3, 8}],
  TestID -> "igusa-maximal-distance"
]

(* Every orbit ends in a cycle: the last partition's image is in the cycle, and the orbit has no repeats *)

VerificationTest[
  AllTrue[IntegerPartitions[14],
    With[{o = BulgarianSolitaireOrbit[#]},
      DuplicateFreeQ[o] && MemberQ[o, BulgarianSolitaireStep[Last[o]]]] &],
  True,
  TestID -> "orbit-closes"
]


(* Periodic partitions (Toom's criterion) agree with iterating the move *)

VerificationTest[
  AllTrue[Flatten[IntegerPartitions /@ Range[1, 16], 1],
    BulgarianSolitairePeriodicQ[#] === (BulgarianSolitaireDistance[#] == 0) &],
  True,
  TestID -> "periodic-matches-distance"
]
VerificationTest[BulgarianSolitairePeriodicQ[{5, 4, 4, 2, 2, 1}], True, TestID -> "periodic-example"]
VerificationTest[BulgarianSolitairePeriodicQ[{5, 4, 1}], False, TestID -> "not-periodic-example"]
VerificationTest[
  Select[IntegerPartitions[15], BulgarianSolitairePeriodicQ],
  {{5, 4, 3, 2, 1}},
  TestID -> "triangular-single-periodic-point"
]


(* Cycles: two for n = 8 (listed in the Manhattanville slides), three for n = 17 *)

VerificationTest[
  Sort[Sort /@ BulgarianSolitaireCycles[8]],
  Sort[Sort /@ {{{4, 2, 2}, {3, 3, 1, 1}}, {{4, 3, 1}, {3, 3, 2}, {3, 2, 2, 1}, {4, 2, 1, 1}}}],
  TestID -> "cycles-8"
]
VerificationTest[Length[BulgarianSolitaireCycles[17]], 3, TestID -> "cycles-17-count"]
VerificationTest[BulgarianSolitaireCycles[6], {{{3, 2, 1}}}, TestID -> "cycles-triangular"]
VerificationTest[BulgarianSolitaireCycles[1], {{{1}}}, TestID -> "cycles-1"]

(* The cycles built from Toom's criterion are the cycles reached from all partitions *)

VerificationTest[
  AllTrue[Range[1, 18],
    Sort[Sort /@ BulgarianSolitaireCycles[#]] ===
      Sort[Sort /@ DeleteDuplicates[Sort /@ (BulgarianSolitaireCycle /@ IntegerPartitions[#])]] &],
  True,
  TestID -> "cycles-match-brute-force"
]

(* Cycle partitions are all of the periodic ones *)

VerificationTest[
  AllTrue[Range[1, 18],
    Sort[Flatten[BulgarianSolitaireCycles[#], 1]] === Sort[Select[IntegerPartitions[#], BulgarianSolitairePeriodicQ]] &],
  True,
  TestID -> "cycles-cover-periodic-partitions"
]

(* Cycle count: 2 at n = 8 and n = 12, 3 at n = 17, 1 at the other n up to 12 *)

VerificationTest[
  Table[BulgarianSolitaireCycleCount[n], {n, 1, 12}],
  {1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2},
  TestID -> "cycle-count-first-12"
]
VerificationTest[BulgarianSolitaireCycleCount[17], 3, TestID -> "cycle-count-17"]
VerificationTest[
  Table[BulgarianSolitaireCycleCount[n], {n, 1, 40}],
  Table[Length[BulgarianSolitaireCycles[n]], {n, 1, 40}],
  TestID -> "cycle-count-matches-cycles"
]


(* Garden of Eden partitions *)

VerificationTest[BulgarianSolitaireGardenOfEdenQ[{4, 4, 3, 3, 2, 2, 2}], True, TestID -> "ge-paper-example"]
VerificationTest[BulgarianSolitaireGardenOfEdenQ[{3, 3, 2, 1, 1}], True, TestID -> "ge-figure-1"]
VerificationTest[BulgarianSolitaireGardenOfEdenQ[{3, 2, 1}], False, TestID -> "ge-staircase-has-preimage"]

(* Gardner's three examples for n = 6 *)

VerificationTest[
  Sort[BulgarianSolitaireGardenOfEdenPartitions[6]],
  Sort[{{2, 2, 1, 1}, {2, 1, 1, 1, 1}, {1, 1, 1, 1, 1, 1}}],
  TestID -> "ge-partitions-6"
]

(* A partition is Garden of Eden exactly when it has no preimage *)

VerificationTest[
  AllTrue[Flatten[IntegerPartitions /@ Range[1, 16], 1],
    BulgarianSolitaireGardenOfEdenQ[#] === (BulgarianSolitairePreimages[#] === {}) &],
  True,
  TestID -> "ge-iff-no-preimage"
]

(* Preimages: each maps back, and together they are all the partitions that map to p *)

VerificationTest[
  BulgarianSolitairePreimages[{6, 5}],
  Sort[{{7, 1, 1, 1, 1}, {6, 1, 1, 1, 1, 1}}],
  TestID -> "preimages-example"
]
VerificationTest[
  AllTrue[Range[1, 14],
    Function[n,
      With[{parts = IntegerPartitions[n]},
        AllTrue[parts,
          Function[p, BulgarianSolitairePreimages[p] === Sort[Select[parts, BulgarianSolitaireStep[#] === p &]]]]]]],
  True,
  TestID -> "preimages-match-brute-force"
]

(* Hopkins-Sellers: ge(n) = p(n-3) - p(n-9) + p(n-18) - ... *)

VerificationTest[
  Table[BulgarianSolitaireGardenOfEdenCount[n], {n, 1, 12}],
  {0, 0, 1, 1, 2, 3, 5, 7, 10, 14, 20, 27},
  TestID -> "ge-count-first-12"
]
VerificationTest[BulgarianSolitaireGardenOfEdenCount[6], 3, TestID -> "ge-count-6"]
VerificationTest[BulgarianSolitaireGardenOfEdenCount[10], 14, TestID -> "ge-count-10"]
VerificationTest[
  Table[BulgarianSolitaireGardenOfEdenCount[n], {n, 1, 40}],
  Table[Length[BulgarianSolitaireGardenOfEdenPartitions[n]], {n, 1, 40}],
  TestID -> "ge-count-matches-enumeration"
]


(* The game graph *)

VerificationTest[
  {VertexCount[#], EdgeCount[#]} &[BulgarianSolitaireGraph[10]],
  {42, 42},
  TestID -> "graph-10-sizes"
]
VerificationTest[
  Sort[VertexOutComponent[BulgarianSolitaireGraph[10], {3, 3, 2, 1, 1}]],
  Sort[BulgarianSolitaireOrbit[{3, 3, 2, 1, 1}]],
  TestID -> "graph-10-out-component"
]


(* Level sizes of the game tree *)

(* n = 6: the 11 partitions are at distances 0, 1, 2, ..., 6 from (3, 2, 1) *)

VerificationTest[BulgarianSolitaireLevelSizes[6], {1, 1, 2, 3, 2, 1, 1}, TestID -> "level-sizes-6"]
VerificationTest[BulgarianSolitaireLeafSizes[6], {0, 0, 0, 1, 1, 0, 1}, TestID -> "leaf-sizes-6"]

(* n = 10: Figure 2 of Eriksson-Jonsson; 42 partitions in 13 levels, 14 leaves *)

VerificationTest[
  BulgarianSolitaireLevelSizes[10],
  {1, 1, 3, 5, 5, 3, 4, 4, 4, 3, 3, 3, 3},
  TestID -> "level-sizes-10"
]
VerificationTest[
  BulgarianSolitaireLeafSizes[10],
  {0, 0, 0, 1, 3, 1, 1, 1, 2, 1, 1, 0, 3},
  TestID -> "leaf-sizes-10"
]
VerificationTest[
  BulgarianSolitaireLevels[10][[1]],
  {{4, 3, 2, 1}},
  TestID -> "levels-10-root"
]
VerificationTest[
  BulgarianSolitaireLevels[10][[13]],
  {{3, 3, 2, 1, 1}, {3, 2, 2, 2, 1}, {3, 2, 2, 1, 1, 1}},
  SameTest -> (Sort[#1] === Sort[#2] &),
  TestID -> "levels-10-deepest"
]

(* The levels partition the partitions, and the height of the tree is k(k - 1) when n = k(k + 1)/2 *)

VerificationTest[
  AllTrue[Range[1, 20], Total[BulgarianSolitaireLevelSizes[#]] == PartitionsP[#] &],
  True,
  TestID -> "levels-sum-to-p"
]
VerificationTest[
  Table[Length[BulgarianSolitaireLevelSizes[k (k + 1)/2]] - 1, {k, 2, 7}],
  Table[k (k - 1), {k, 2, 7}],
  TestID -> "tree-height"
]
VerificationTest[
  AllTrue[Range[1, 20], Total[BulgarianSolitaireLeafSizes[#]] == BulgarianSolitaireGardenOfEdenCount[#] &],
  True,
  TestID -> "leaves-sum-to-ge"
]

(* Eriksson-Jonsson Theorem 5.1 for n = k(k + 1)/2: levels 0 .. Floor[k/2] have the quasi-infinite sizes,
   and level Floor[k/2] + 1 is short by 1 (k odd) or 1 + k/2 (k even) *)

VerificationTest[
  Table[
    Take[BulgarianSolitaireLevelSizes[k (k + 1)/2], Floor[k/2] + 1],
    {k, 3, 8}],
  Table[Table[BulgarianSolitaireQuasiLevelSize[d], {d, 0, Floor[k/2]}], {k, 3, 8}],
  TestID -> "theorem-5-1-levels"
]
VerificationTest[
  Table[
    With[{d = Floor[k/2] + 1},
      BulgarianSolitaireQuasiLevelSize[d] - BulgarianSolitaireLevelSizes[k (k + 1)/2][[d + 1]]],
    {k, 3, 8}],
  Table[If[OddQ[k], 1, 1 + k/2], {k, 3, 8}],
  TestID -> "theorem-5-1-deficit"
]


(* Quasi-infinite level sizes: F(2d) and the leaf counts of the paper *)

VerificationTest[
  Table[BulgarianSolitaireQuasiLevelSize[d], {d, 0, 8}],
  {1, 1, 3, 8, 21, 55, 144, 377, 987},
  TestID -> "quasi-level-sizes"
]
VerificationTest[
  Table[BulgarianSolitaireQuasiLeafSize[d], {d, 0, 7}],
  {0, 0, 0, 1, 3, 9, 25, 68},
  TestID -> "quasi-leaf-sizes"
]

(* The leaf generating function (x^3 - x^4)/((1 - x - x^2)(1 - 3x + x^2)) *)

VerificationTest[
  CoefficientList[Series[(x^3 - x^4)/((1 - x - x^2) (1 - 3 x + x^2)), {x, 0, 20}], x],
  Table[BulgarianSolitaireQuasiLeafSize[d], {d, 0, 20}],
  TestID -> "quasi-leaf-generating-function"
]

(* The generating function g = (1 - x)/(1 - 3x + x^2) has coefficients Fibonacci[2d + 1], and h = (1 - x) g has F(2d) *)

VerificationTest[
  CoefficientList[Series[(1 - x)^2/(1 - 3 x + x^2), {x, 0, 20}], x],
  Table[BulgarianSolitaireQuasiLevelSize[d], {d, 0, 20}],
  TestID -> "quasi-level-generating-function"
]


(* The row-to-column game of Hopkins *)

VerificationTest[
  BulgarianSolitaireRowMoves[{6, 4, 3, 1, 1}],
  Sort[{{5, 5, 3, 2}, {5, 3, 3, 2, 1, 1}, {5, 4, 3, 1, 1, 1}}],
  TestID -> "row-moves-example"
]
VerificationTest[BulgarianSolitaireRowMoves[{10}], {{9, 1}}, TestID -> "row-moves-first-move"]
VerificationTest[BulgarianSolitaireRowMoves[{9, 1}], Sort[{{8, 2}, {8, 1, 1}}], TestID -> "row-moves-second-move"]
VerificationTest[
  AllTrue[Flatten[IntegerPartitions /@ Range[1, 12], 1],
    MemberQ[BulgarianSolitaireRowMoves[#], BulgarianSolitaireStep[#]] &],
  True,
  TestID -> "row-moves-include-step"
]
VerificationTest[
  AllTrue[Flatten[IntegerPartitions /@ Range[1, 12], 1],
    Function[p, AllTrue[BulgarianSolitaireRowMoves[p], OEIS`Private`bsPartitionQ[#] && Total[#] == Total[p] &]]],
  True,
  TestID -> "row-moves-are-partitions"
]


(* Level sizes of one cycle (Pham) *)

VerificationTest[BulgarianSolitairePeriodicPartition[{1, 0, 1, 0}], {4, 2, 2}, TestID -> "necklace-partition-bw"]
VerificationTest[BulgarianSolitairePeriodicPartition[{1, 1, 0, 0}], {4, 3, 1}, TestID -> "necklace-partition-bbww"]
VerificationTest[BulgarianSolitairePeriodicPartition[{0, 0, 0}], {2, 1}, TestID -> "necklace-partition-staircase"]
VerificationTest[
  AllTrue[{{1, 0, 1, 0, 0}, {1, 1, 0, 1, 0, 0}},
    BulgarianSolitairePeriodicQ[BulgarianSolitairePeriodicPartition[#]] &],
  True,
  TestID -> "necklace-partition-is-periodic"
]
(* A necklace must be a nonempty list of 0s and 1s: otherwise a message and $Failed *)

VerificationTest[
  BulgarianSolitairePeriodicPartition[{2, 0}], $Failed,
  {BulgarianSolitairePeriodicPartition::necklace}, TestID -> "necklace-bad-bead-message"
]
VerificationTest[
  BulgarianSolitairePeriodicPartition[{}], $Failed,
  {BulgarianSolitairePeriodicPartition::necklace}, TestID -> "necklace-empty-message"
]
VerificationTest[
  BulgarianSolitairePeriodicPartition[7], $Failed,
  {BulgarianSolitairePeriodicPartition::necklace}, TestID -> "necklace-integer-message"
]
VerificationTest[
  BulgarianSolitairePeriodicPartition[{1, 0, "a"}], $Failed,
  {BulgarianSolitairePeriodicPartition::necklace}, TestID -> "necklace-string-bead-message"
]
VerificationTest[
  StringContainsQ[ToString[BulgarianSolitairePeriodicPartition::necklace], "not a necklace"], True,
  TestID -> "necklace-message-text"
]

(* For triangular n the basin of the fixed point is the whole game tree *)

VerificationTest[
  Table[
    BulgarianSolitaireBasinLevelSizes[BulgarianSolitairePeriodicPartition[ConstantArray[0, k + 1]]] ===
      BulgarianSolitaireLevelSizes[k (k + 1)/2],
    {k, 3, 5}],
  {True, True, True},
  TestID -> "basin-of-fixed-point-is-tree"
]

(* The basins of the cycles together hold every partition of n *)

VerificationTest[
  AllTrue[Range[1, 20],
    Total[Total /@ (BulgarianSolitaireBasinLevelSizes[First[#]] & /@ BulgarianSolitaireCycles[#])] == PartitionsP[#] &],
  True,
  TestID -> "basins-cover-all-partitions"
]

(* Pham: necklace BW repeated l times, levels from the brute-force run *)

VerificationTest[
  Table[BulgarianSolitaireBasinLevelSizes[BulgarianSolitairePeriodicPartition[Flatten[ConstantArray[{1, 0}, l]]]], {l, 2, 5}],
  {{2, 1, 2, 2}, {2, 1, 3, 6, 8, 6}, {2, 1, 3, 7, 14, 24, 28, 18}, {2, 1, 3, 7, 15, 32, 60, 92, 96, 54}},
  TestID -> "basin-levels-bw"
]

(* The first l levels equal the coefficients of H_BW(x) = (x - 1)^2 (3x + 2)/(x^3 - 3x^2 - x + 1) *)

VerificationTest[
  CoefficientList[Series[(x - 1)^2 (3 x + 2)/(x^3 - 3 x^2 - x + 1), {x, 0, 7}], x],
  {2, 1, 3, 7, 15, 33, 71, 155},
  TestID -> "h-bw-series"
]
VerificationTest[
  With[{h = CoefficientList[Series[(x - 1)^2 (3 x + 2)/(x^3 - 3 x^2 - x + 1), {x, 0, 7}], x]},
    Table[
      With[{lv = BulgarianSolitaireBasinLevelSizes[BulgarianSolitairePeriodicPartition[Flatten[ConstantArray[{1, 0}, l]]]]},
        Take[lv, l] === Take[h, l] && Length[lv] == 2 l],
      {l, 2, 8}]],
  ConstantArray[True, 7],
  TestID -> "basin-levels-bw-converge-to-h-bw"
]


(* Examples from docs/BulgarianSolitaire.md *)

VerificationTest[BulgarianSolitaireStep[{6, 4, 3, 1, 1}], {5, 5, 3, 2}, TestID -> "example-step"]
VerificationTest[Length[BulgarianSolitaireOrbit[{6, 4, 3, 1, 1}]], 8, TestID -> "example-orbit-length"]
VerificationTest[BulgarianSolitaireGardenOfEdenCount[20],
  PartitionsP[17] - PartitionsP[11] + PartitionsP[2],
  TestID -> "example-ge-20"
]

(* Function Repository examples (need an internet connection the first time) *)

VerificationTest[
  ResourceFunction["HookLengths"][{6, 4, 3, 1, 1}],
  {{10, 7, 6, 4, 2, 1}, {7, 4, 3, 1}, {5, 2, 1}, {2}, {1}},
  TestID -> "example-hook-lengths"
]
VerificationTest[
  Module[{hookCount},
    hookCount[p_] := Total[p]!/Times @@ Flatten[ResourceFunction["HookLengths"][p]];
    hookCount /@ BulgarianSolitaireOrbit[{6, 4, 3, 1, 1}]],
  {231660, 96525, 75075, 100100, 125125, 210210, 175175, 292864},
  TestID -> "example-hook-count-orbit"
]
VerificationTest[
  {Length[ResourceFunction["StandardYoungTableaux"][{4, 3, 2, 1}]],
   ResourceFunction["StandardYoungTableaux"][{2, 1}]},
  {768, {{{1, 2}, {3}}, {{1, 3}, {2}}}},
  TestID -> "example-standard-young-tableaux"
]


(* MaxDistance, CycleLengths, Component, ReversedTree *)

VerificationTest[
  BulgarianSolitaireMaxDistance /@ Range[16],
  {0, 0, 2, 2, 3, 6, 4, 5, 7, 12, 8, 8, 9, 14, 20, 15},
  TestID -> "max-distance-values"
]
VerificationTest[
  Table[BulgarianSolitaireMaxDistance[k (k + 1)/2], {k, 2, 7}],
  Table[k (k - 1), {k, 2, 7}],
  TestID -> "max-distance-staircase-igusa"
]
VerificationTest[
  Table[BulgarianSolitaireMaxDistance[n] == Max[BulgarianSolitaireDistance /@ IntegerPartitions[n]], {n, 1, 14}],
  ConstantArray[True, 14],
  TestID -> "max-distance-vs-distance"
]
VerificationTest[
  BulgarianSolitaireCycleLengths /@ {8, 17, 12, 20},
  {{2, 4}, {3, 6, 6}, {5, 5}, {6}},
  TestID -> "cycle-lengths-values"
]
VerificationTest[
  Table[Length[BulgarianSolitaireCycleLengths[n]] == BulgarianSolitaireCycleCount[n], {n, 1, 30}],
  ConstantArray[True, 30],
  TestID -> "cycle-lengths-count"
]
VerificationTest[
  Table[Sort[Flatten[BulgarianSolitaireComponent /@ First /@ BulgarianSolitaireCycles[n], 1]] === Sort[IntegerPartitions[n]], {n, 1, 14}],
  ConstantArray[True, 14],
  TestID -> "components-partition-the-partitions"
]
VerificationTest[
  With[{c = BulgarianSolitaireComponent[{6, 4, 3, 1, 1}]},
    {Length[c], c === BulgarianSolitaireComponent[{5, 4, 3, 2, 1}], AllTrue[c, BulgarianSolitaireCycle[#] === {{5, 4, 3, 2, 1}} &]}],
  {176, True, True},
  TestID -> "component-staircase-15"
]
VerificationTest[
  With[{g = BulgarianSolitaireReversedTree[{4, 3, 2, 1}]},
    {VertexCount[g], EdgeCount[g], TreeGraphQ[g], Sort[VertexList[g]] === Sort[BulgarianSolitaireComponent[{4, 3, 2, 1}]]}],
  {42, 41, True, True},
  TestID -> "reversed-tree-staircase-10"
]
VerificationTest[
  With[{g = BulgarianSolitaireReversedTree[{2, 1, 1}]}, {VertexCount[g], EdgeCount[g]}],
  {5, 2},
  TestID -> "reversed-tree-cycle-of-3"
]


(* OEIS A123975: number of Garden of Eden partitions of n *)

VerificationTest[
  BulgarianSolitaireGardenOfEdenCount /@ Range[20],
  {0, 0, 1, 1, 2, 3, 5, 7, 10, 14, 20, 27, 37, 49, 66, 86, 113, 147, 190, 243},
  TestID -> "ge-count-a123975"
]


(* Integer arguments: n must be a positive integer, and d a nonnegative integer *)

VerificationTest[
  BulgarianSolitaireLevelSizes[0], $Failed, {BulgarianSolitaireLevelSizes::posint},
  TestID -> "n-zero-message"
]
VerificationTest[
  BulgarianSolitaireCycleCount[-3], $Failed, {BulgarianSolitaireCycleCount::posint},
  TestID -> "n-negative-message"
]
VerificationTest[
  BulgarianSolitaireCycles[2.5], $Failed, {BulgarianSolitaireCycles::posint},
  TestID -> "n-real-message"
]
VerificationTest[
  BulgarianSolitaireGardenOfEdenCount[{4, 3}], $Failed, {BulgarianSolitaireGardenOfEdenCount::posint},
  TestID -> "n-list-message"
]
VerificationTest[
  Quiet[
    (#[0] & /@ {BulgarianSolitaireCycles, BulgarianSolitaireCycleCount, BulgarianSolitaireGardenOfEdenCount,
       BulgarianSolitaireGardenOfEdenPartitions, BulgarianSolitaireGraph, BulgarianSolitaireLevels,
       BulgarianSolitaireLevelSizes, BulgarianSolitaireLeafSizes, BulgarianSolitaireMaxDistance,
       BulgarianSolitaireCycleLengths}),
    {BulgarianSolitaireCycles::posint, BulgarianSolitaireCycleCount::posint,
     BulgarianSolitaireGardenOfEdenCount::posint, BulgarianSolitaireGardenOfEdenPartitions::posint,
     BulgarianSolitaireGraph::posint, BulgarianSolitaireLevels::posint, BulgarianSolitaireLevelSizes::posint,
     BulgarianSolitaireLeafSizes::posint, BulgarianSolitaireMaxDistance::posint,
     BulgarianSolitaireCycleLengths::posint}],
  ConstantArray[$Failed, 10],
  TestID -> "all-n-functions-fail"
]
VerificationTest[
  BulgarianSolitaireGraph[0, VertexLabels -> "Name"], $Failed, {BulgarianSolitaireGraph::posint},
  TestID -> "graph-with-options-message"
]
VerificationTest[
  {BulgarianSolitaireQuasiLevelSize[-1], BulgarianSolitaireQuasiLeafSize[1/2]}, {$Failed, $Failed},
  {BulgarianSolitaireQuasiLevelSize::nonnegint, BulgarianSolitaireQuasiLeafSize::nonnegint},
  TestID -> "d-message"
]
VerificationTest[
  {BulgarianSolitaireQuasiLevelSize[0], BulgarianSolitaireQuasiLeafSize[0], BulgarianSolitaireQuasiLevelSize[3]},
  {1, 0, 8},
  TestID -> "d-zero-is-valid"
]
VerificationTest[
  StringContainsQ[ToString[BulgarianSolitaireCycles::posint], "positive integer"], True,
  TestID -> "posint-message-text"
]
