(* ::Package:: *)

(* Partitions of n counted by rank, the largest part minus the number of parts; A101198 is rank 1. The counts come from Dyson's rank generating function, equation (2.12) of Atkin and Swinnerton-Dyer, Some properties of partitions, Proc. London Math. Soc. (3) 4 (1954), 84-106, where it is proved as Lemma 1. *)

BeginPackage["OEIS`"];

A101198::usage = "A101198[n] gives the number of partitions of n with rank 1, where the rank of a partition is its largest part minus its number of parts.";
PartitionRankCount::usage = "PartitionRankCount[m, n] gives N(m, n), the number of partitions of n with rank m: as a sum of about Sqrt[2n/3] differences of partition numbers p(n - k(3k-1)/2 - |m| k) - p(n - k(3k+1)/2 - |m| k).";
PartitionRankCountList::usage = "PartitionRankCountList[m, nmax] gives {N(m, 1), ..., N(m, nmax)}, the numbers of partitions of 1, ..., nmax with rank m.";

Begin["`Private`"];


(* ::Subsection:: *)
(*Dyson's rank generating function*)


(* ::Text:: *)
(*For m >= 0, Sum_{n>=1} N(m, n) x^n = Sum_{k>=1} (-1)^(k-1) x^(k(3k-1)/2 + m k) (1 - x^k) / Prod_{r>=1} (1 - x^r). This is (2.12) of Atkin and Swinnerton-Dyer, who credit it to Dyson and prove it in their Lemma 1: removing the largest part s + m from a partition with s parts leaves s - 1 parts of size at most s + m, and two identities of Cauchy (Hardy and Wright, Theorems 348 and 349) sum the result over s. Conjugation turns rank m into rank -m, so N(-m, n) = N(m, n).*)


(* ::Subsection:: *)
(*One term*)


(* ::Text:: *)
(*Expanding 1/Prod(1 - x^r) = Sum p(j) x^j and reading off the coefficient of x^n gives N(m, n) = Sum_{k>=1} (-1)^(k-1) (p(n - k(3k-1)/2 - m k) - p(n - k(3k+1)/2 - m k)), with p(j) = 0 for j < 0 (PartitionsP gives 0 there). The sum stops once k(3k-1)/2 + m k > n, so k <= (1 + Sqrt[1 + 24 n])/6 is enough; for m = 1 the two offsets are k(3k+1)/2 and 3k(k+1)/2.*)


PartitionRankCount[m_Integer, n_Integer?Positive] :=
  Sum[(-1)^(k - 1) (PartitionsP[n - k (3 k - 1)/2 - Abs[m] k] - PartitionsP[n - k (3 k + 1)/2 - Abs[m] k]),
    {k, 1, Floor[(Sqrt[24 n + 1] + 1)/6]}]

A101198[n_Integer?Positive] := PartitionRankCount[1, n]


(* ::Subsection:: *)
(*Many terms*)


PartitionRankCountList[m_Integer, nmax_Integer?Positive] := Table[PartitionRankCount[m, n], {n, nmax}]


(* ::Subsection:: *)
(*Invalid arguments*)


(* ::Text:: *)
(*Each function gives a message and returns $Failed when n or nmax is not a positive integer (A101198 starts at n = 1, like the OEIS entry), or when the rank m is not an integer.*)


MessageName[A101198, "posint"] = "`1` is not a positive integer.";
A101198[n_] /; ! (IntegerQ[n] && n > 0) := (Message[A101198::posint, n]; $Failed)

Scan[
  Function[f,
    MessageName[f, "int"] = "`1` is not an integer.";
    MessageName[f, "posint"] = "`1` is not a positive integer.";
    f[m_, _] /; ! IntegerQ[m] := (Message[f::int, m]; $Failed);
    f[_Integer, n_] /; ! (IntegerQ[n] && n > 0) := (Message[f::posint, n]; $Failed)],
  {PartitionRankCount, PartitionRankCountList}]


End[];

EndPackage[];
