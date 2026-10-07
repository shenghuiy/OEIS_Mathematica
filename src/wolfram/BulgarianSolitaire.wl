(* ::Package:: *)

(* Bulgarian solitaire on integer partitions: the move, orbits and cycles, Garden of Eden partitions, and the level sizes of the game tree. *)

BeginPackage["OEIS`"];

BulgarianSolitaireStep::usage = "BulgarianSolitaireStep[p] gives the partition after one move of Bulgarian solitaire on the partition p, a list of positive integers in non-increasing order: take one card from each pile and make a new pile.";
BulgarianSolitaireOrbit::usage = "BulgarianSolitaireOrbit[p] lists p, its image, and so on, stopping just before the first partition that repeats.";
BulgarianSolitaireCycle::usage = "BulgarianSolitaireCycle[p] gives the cycle that p ends in, as a list of partitions starting with the first one reached. A fixed point is a cycle of length 1.";
BulgarianSolitaireDistance::usage = "BulgarianSolitaireDistance[p] gives the number of moves before p first reaches its cycle.";
BulgarianSolitairePeriodicQ::usage = "BulgarianSolitairePeriodicQ[p] tests whether p lies on a cycle, using Toom's diagonal criterion: the Ferrers diagram has k cells on diagonal k for k <= m, n - m(m+1)/2 cells on diagonal m+1, and none beyond, where m(m+1)/2 <= n < (m+1)(m+2)/2.";
BulgarianSolitaireCycles::usage = "BulgarianSolitaireCycles[n] lists every cycle of partitions of n, each starting at its smallest partition in canonical order. The cycles are built from the periodic partitions, one for each choice of cells on diagonal m+1, so the cost grows like Binomial[m+1, n - m(m+1)/2].";
BulgarianSolitaireCycleCount::usage = "BulgarianSolitaireCycleCount[n] gives the number of cycles of partitions of n, counted as necklaces with the Polya enumeration formula of Brandt, without building any partition.";
BulgarianSolitaireGardenOfEdenQ::usage = "BulgarianSolitaireGardenOfEdenQ[p] tests whether p has no preimage under BulgarianSolitaireStep, which happens exactly when its rank, the largest part minus the number of parts, is at most -2.";
BulgarianSolitaireGardenOfEdenCount::usage = "BulgarianSolitaireGardenOfEdenCount[n] gives the number of Garden of Eden partitions of n, from the Hopkins-Sellers formula p(n-3) - p(n-9) + p(n-18) - ... with p(n - 3j(j+1)/2).";
BulgarianSolitaireGardenOfEdenPartitions::usage = "BulgarianSolitaireGardenOfEdenPartitions[n] lists the partitions of n with no preimage.";
BulgarianSolitairePreimages::usage = "BulgarianSolitairePreimages[p] lists the partitions that BulgarianSolitaireStep sends to p, one for each distinct part of p that is at least the number of parts minus 1.";
BulgarianSolitaireGraph::usage = "BulgarianSolitaireGraph[n] gives the directed graph on the partitions of n with an edge from each partition to its image. Options are passed to Graph.";
BulgarianSolitaireLevels::usage = "BulgarianSolitaireLevels[n] gives the partitions of n grouped by distance to the cycles: element d + 1 lists the partitions that take exactly d moves to reach a cycle.";
BulgarianSolitaireLevelSizes::usage = "BulgarianSolitaireLevelSizes[n] gives the number of partitions of n at each distance 0, 1, 2, ... from the cycles. For n = k(k+1)/2 this is the level sizes of the game tree rooted at the staircase partition.";
BulgarianSolitaireLeafSizes::usage = "BulgarianSolitaireLeafSizes[n] gives the number of Garden of Eden partitions of n at each distance 0, 1, 2, ... from the cycles, that is, the leaves on each level of the game tree.";
BulgarianSolitaireQuasiLevelSize::usage = "BulgarianSolitaireQuasiLevelSize[d] gives the number of partitions at distance d from the staircase in the quasi-infinite game (k -> Infinity): 1 for d = 0 and Fibonacci[2d] after that. For n = k(k+1)/2 it equals the actual level size for d <= Floor[k/2].";
BulgarianSolitaireQuasiLeafSize::usage = "BulgarianSolitaireQuasiLeafSize[d] gives the number of leaves at distance d from the staircase in the quasi-infinite game: (Fibonacci[2d-2] - Fibonacci[d-1])/2 for d >= 1.";
BulgarianSolitaireRowMoves::usage = "BulgarianSolitaireRowMoves[p] lists the partitions reachable when any one row of the Ferrers diagram of p is changed into a column, the move of the two-player game in Hopkins' 30 Years of Bulgarian Solitaire. Removing the bottom row is BulgarianSolitaireStep.";
BulgarianSolitairePeriodicPartition::usage = "BulgarianSolitairePeriodicPartition[w] gives the partition on a cycle that corresponds to the necklace w, a list of m + 1 beads, 1 for a filled cell on diagonal m + 1 and 0 for an empty one. Rotating w gives the next partition on the same cycle.";
BulgarianSolitaireBasinLevelSizes::usage = "BulgarianSolitaireBasinLevelSizes[p] gives the number of partitions at each distance 0, 1, 2, ... from the cycle that p ends in, counting only the partitions that flow into that cycle. Level 0 is the cycle itself.";
BulgarianSolitaireMaxDistance::usage = "BulgarianSolitaireMaxDistance[n] gives the largest number of moves any partition of n needs to reach a cycle, the height of the game tree. For n = k(k+1)/2 it is k(k - 1) (Igusa).";
BulgarianSolitaireCycleLengths::usage = "BulgarianSolitaireCycleLengths[n] gives the sorted lengths of the cycles of partitions of n, one entry per cycle.";
BulgarianSolitaireComponent::usage = "BulgarianSolitaireComponent[p] lists the partitions in the connected component of p: the cycle p ends in and every partition that flows into it, in order of distance from the cycle.";
BulgarianSolitaireReversedTree::usage = "BulgarianSolitaireReversedTree[p] gives the graph of the component of p with the edges reversed, from each partition to its preimages, leaving out the edges into the cycle. Options are passed to Graph.";

Begin["`Private`"];


(* ::Subsection:: *)
(*The move*)


(* ::Text:: *)
(*A partition is a nonempty list of positive integers in non-increasing order. A move subtracts 1 from every part, drops the zeros, and adds a part equal to the old number of parts.*)


bsPartitionQ[l_] := ListQ[l] && l =!= {} && VectorQ[l, IntegerQ[#] && # > 0 &] && OrderedQ[Reverse[l]]

bsStep[l_List] := Sort[Append[DeleteCases[l - 1, 0], Length[l]], Greater]

BulgarianSolitaireStep[l_?bsPartitionQ] := bsStep[l]


(* ::Subsection:: *)
(*Orbits and cycles*)


(* ::Text:: *)
(*bsOrbitData returns the orbit up to the first repeat together with the position (from 0) of the repeated partition, which is the number of moves before the cycle is reached. The orbit from there on is the cycle.*)


bsOrbitData[l_List] := Module[{seen = <||>, cur = l, i = 0, orbit},
  orbit = First[Reap[While[! KeyExistsQ[seen, cur], seen[cur] = ++i; Sow[cur]; cur = bsStep[cur]]][[2]]];
  {orbit, seen[cur] - 1}
]

BulgarianSolitaireOrbit[l_?bsPartitionQ] := First[bsOrbitData[l]]

BulgarianSolitaireDistance[l_?bsPartitionQ] := Last[bsOrbitData[l]]

BulgarianSolitaireCycle[l_?bsPartitionQ] := With[{d = bsOrbitData[l]}, Drop[First[d], Last[d]]]


(* ::Subsection:: *)
(*Periodic partitions (Toom, Brandt)*)


(* ::Text:: *)
(*Draw the partition as checkers on an infinite board, row i holding the i-th part, and let diag[k] be the cells (i, j) with i + j - 1 = k. A move never carries a checker from diag[k] to diag[k+1], so the partitions on a cycle are exactly those whose diagonals are full up to m, partly filled on m + 1, and empty beyond, where m(m+1)/2 <= n < (m+1)(m+2)/2 (Hart, Khan, Khan, Theorem 2.1).*)


bsTriangularRoot[n_Integer] := Floor[(Floor[Sqrt[8 n + 1]] - 1)/2]

bsDiagonalCounts[l_List] := Counts[Flatten[MapIndexed[(First[#2] + Range[#1] - 1) &, l]]]

bsPeriodicQ[l_List] := Module[{n = Total[l], m, r, want},
  m = bsTriangularRoot[n];
  r = n - m (m + 1)/2;
  want = Join[AssociationThread[Range[m] -> Range[m]], If[r > 0, <|m + 1 -> r|>, <||>]];
  KeySort[bsDiagonalCounts[l]] === want
]

BulgarianSolitairePeriodicQ[l_?bsPartitionQ] := bsPeriodicQ[l]


(* ::Text:: *)
(*Every choice of r = n - m(m+1)/2 cells on diagonal m + 1 gives a periodic partition: row i has m + 1 - i cells on the smaller diagonals, plus one if its cell on diagonal m + 1 is chosen. Each cycle is then read off by iterating the move, and rotated to start at its smallest partition so that a cycle is listed once.*)


bsCanonicalCycle[l_List] := With[{c = First[bsOrbitData[l]]}, RotateLeft[c, First[Ordering[c, 1]] - 1]]

BulgarianSolitaireCycles[n_Integer?Positive] := Module[{m = bsTriangularRoot[n], r},
  r = n - m (m + 1)/2;
  Union[Table[
    bsCanonicalCycle[DeleteCases[Table[m + 1 - i + Boole[MemberQ[s, i]], {i, m + 1}], 0]],
    {s, Subsets[Range[m + 1], {r}]}]]
]


(* ::Text:: *)
(*The cycles are the necklaces of m + 1 beads, r of them marked, under rotation, since a move rotates diagonal m + 1. Burnside's lemma gives (1/(m+1)) Sum over d | gcd(m+1, r) of EulerPhi[d] Binomial[(m+1)/d, r/d].*)


BulgarianSolitaireCycleCount[n_Integer?Positive] := Module[{m = bsTriangularRoot[n], r, len},
  len = m + 1;
  r = n - m (m + 1)/2;
  Total[(EulerPhi[#] Binomial[len/#, r/#]) & /@ Divisors[GCD[len, r]]]/len
]


(* ::Subsection:: *)
(*Garden of Eden partitions (Hopkins, Sellers)*)


(* ::Text:: *)
(*A partition (l1, ..., lt) has a preimage for each distinct part v >= t - 1: add 1 to every other part and append v - t + 1 ones. So there is none exactly when l1 - t <= -2. Counting those partitions by Dyson's rank generating function gives ge(n) = Sum (-1)^(j+1) p(n - 3j(j+1)/2).*)


bsGardenOfEdenQ[l_List] := First[l] - Length[l] <= -2

BulgarianSolitaireGardenOfEdenQ[l_?bsPartitionQ] := bsGardenOfEdenQ[l]

BulgarianSolitaireGardenOfEdenCount[n_Integer?Positive] := Module[{j = 1, s = 0},
  While[3 j (j + 1)/2 <= n, s += (-1)^(j + 1) PartitionsP[n - 3 j (j + 1)/2]; j++];
  s
]

BulgarianSolitaireGardenOfEdenPartitions[n_Integer?Positive] := Select[IntegerPartitions[n], bsGardenOfEdenQ]

bsPreimages[l_List] := With[{t = Length[l]},
  Sort[Table[
    Sort[Join[Delete[l, FirstPosition[l, v]] + 1, ConstantArray[1, v - t + 1]], Greater],
    {v, Select[Union[l], # >= t - 1 &]}]]
]

BulgarianSolitairePreimages[l_?bsPartitionQ] := bsPreimages[l]


(* ::Subsection:: *)
(*The game graph and its level sizes*)


BulgarianSolitaireGraph[n_Integer?Positive, opts___?OptionQ] := Graph[DirectedEdge[#, bsStep[#]] & /@ IntegerPartitions[n], opts]


(* ::Text:: *)
(*The partitions are grouped by distance to the cycles. Level 0 is the periodic partitions; level d + 1 is the preimages of level d that are not themselves periodic. Every other partition has a single path into a cycle, so each is reached once.*)


bsLevels[n_Integer] := Module[{pre = GroupBy[IntegerPartitions[n], bsStep]},
  Most[NestWhileList[
    Function[lev, Select[Flatten[Lookup[pre, lev, {}], 1], ! bsPeriodicQ[#] &]],
    Select[Keys[pre], bsPeriodicQ],
    # =!= {} &]]
]

BulgarianSolitaireLevels[n_Integer?Positive] := bsLevels[n]

BulgarianSolitaireLevelSizes[n_Integer?Positive] := Length /@ bsLevels[n]

BulgarianSolitaireLeafSizes[n_Integer?Positive] := Count[#, _?bsGardenOfEdenQ] & /@ bsLevels[n]


(* ::Text:: *)
(*Eriksson and Jonsson: as k -> Infinity the tree of partitions of k(k+1)/2 near the staircase has level sizes F(2d), and F(2d) is exact for d <= Floor[k/2]. The leaves on level d number (F(2d-2) - F(d-1))/2.*)


BulgarianSolitaireQuasiLevelSize[0] = 1;
BulgarianSolitaireQuasiLevelSize[d_Integer?Positive] := Fibonacci[2 d]

BulgarianSolitaireQuasiLeafSize[0] = 0;
BulgarianSolitaireQuasiLeafSize[d_Integer?Positive] := (Fibonacci[2 d - 2] - Fibonacci[d - 1])/2


(* ::Subsection:: *)
(*The row-to-column game*)


(* ::Text:: *)
(*In the Ferrers diagram of p with columns of heights p, row j has conj[[j]] cells. Removing row j lowers every column of height at least j by 1, and the removed cells form a new column of height conj[[j]]. Row 1 is the ordinary move.*)


bsRowMoves[l_List] := With[{conj = Table[Total[Boole[# >= j & /@ l]], {j, First[l]}]},
  Union[Table[
    Sort[DeleteCases[Append[If[# >= j, # - 1, #] & /@ l, conj[[j]]], 0], Greater],
    {j, Length[conj]}]]
]

BulgarianSolitaireRowMoves[l_?bsPartitionQ] := bsRowMoves[l]


(* ::Subsection:: *)
(*Level sizes of one cycle (Pham)*)


(* ::Text:: *)
(*A cycle corresponds to a necklace of m + 1 beads, a bead being 1 where a cell of diagonal m + 1 is filled. Row i of the partition has m + 1 - i cells on the smaller diagonals, plus the bead. The partitions that flow into one cycle are found by walking backward through the preimages from the cycle, so only that cycle's basin is visited, not all p(n) partitions. Pham studies the level sizes for the necklace P repeated l times as l grows; they converge to the coefficients of a rational function (Harris and Nguyen, Pham's conjecture).*)


bsPeriodicFromNecklace[w_List] := With[{m1 = Length[w]}, DeleteCases[Table[m1 - i + w[[i]], {i, m1}], 0]]

bsNecklaceQ[w_] := ListQ[w] && w =!= {} && VectorQ[w, MatchQ[#, 0 | 1] &]

BulgarianSolitairePeriodicPartition[w_?bsNecklaceQ] := bsPeriodicFromNecklace[w]

bsBasinLevels[l_List] := Module[{d = bsOrbitData[l], cyc, seen, level, out = {}},
  cyc = Drop[First[d], Last[d]];
  seen = AssociationThread[cyc -> True];
  level = cyc;
  While[level =!= {},
    AppendTo[out, level];
    level = Select[Flatten[bsPreimages /@ level, 1], ! KeyExistsQ[seen, #] &];
    Scan[(seen[#] = True) &, level]];
  out
]

bsBasinLevelSizes[l_List] := Length /@ bsBasinLevels[l]

BulgarianSolitaireBasinLevelSizes[l_?bsPartitionQ] := bsBasinLevelSizes[l]


(* ::Subsection:: *)
(*Maximal distance, cycle lengths, components, and the reversed game tree*)


(* ::Text:: *)
(*The largest distance to a cycle over all partitions of n is the height of the game tree: one less than the number of levels (Igusa: k(k - 1) for n = k(k+1)/2). The cycle lengths are the lengths of the cycles of BulgarianSolitaireCycles. The component of p is its cycle together with every partition that flows into it. The reversed tree turns the edges around, from each partition to its preimages, and leaves out the edges into the cycle. Each partition off the cycle has exactly one parent, so what remains is a tree hanging from each cycle partition, and for a fixed point (such as the staircase) a single tree.*)


BulgarianSolitaireMaxDistance[n_Integer?Positive] := Length[bsLevels[n]] - 1

BulgarianSolitaireCycleLengths[n_Integer?Positive] := Sort[Length /@ BulgarianSolitaireCycles[n]]

BulgarianSolitaireComponent[l_?bsPartitionQ] := Flatten[bsBasinLevels[l], 1]

BulgarianSolitaireReversedTree[l_?bsPartitionQ, opts___?OptionQ] := Module[{levels = bsBasinLevels[l], cyc, all},
  cyc = First[levels];
  all = Flatten[levels, 1];
  Graph[all,
    Flatten[Table[DirectedEdge[q, #] & /@ Complement[bsPreimages[q], cyc], {q, all}]],
    opts]
]


(* ::Subsection:: *)
(*Invalid partitions*)


(* ::Text:: *)
(*Every function that takes a partition gives a message and returns $Failed when its first argument is not one: a nonempty list of positive integers in non-increasing order. BulgarianSolitairePeriodicPartition does the same for a necklace that is not a nonempty list of 0s and 1s.*)


Scan[
  Function[f,
    MessageName[f, "partition"] = "`1` is not a partition: expected a nonempty list of positive integers in non-increasing order.";
    f[l_, ___] /; ! bsPartitionQ[l] := (Message[f::partition, l]; $Failed)],
  {BulgarianSolitaireStep, BulgarianSolitaireOrbit, BulgarianSolitaireCycle, BulgarianSolitaireDistance,
   BulgarianSolitairePeriodicQ, BulgarianSolitaireGardenOfEdenQ, BulgarianSolitairePreimages,
   BulgarianSolitaireRowMoves, BulgarianSolitaireBasinLevelSizes, BulgarianSolitaireComponent,
   BulgarianSolitaireReversedTree}]

MessageName[BulgarianSolitairePeriodicPartition, "necklace"] =
  "`1` is not a necklace: expected a nonempty list of 0s and 1s.";
BulgarianSolitairePeriodicPartition[w_, ___] /; ! bsNecklaceQ[w] :=
  (Message[BulgarianSolitairePeriodicPartition::necklace, w]; $Failed)


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Test*)


(* ::Program:: *)
(*In[]:= BulgarianSolitaireOrbit[{6, 4, 3, 1, 1}]*)
