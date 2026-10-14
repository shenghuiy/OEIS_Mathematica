(* ::Package:: *)

(* Partitions of n with nonnegative rank, where the rank is the largest part minus the number of parts. Summing Dyson's rank generating function, equation (2.12) of Atkin and Swinnerton-Dyer, Some properties of partitions, Proc. London Math. Soc. (3) 4 (1954), 84-106, over all ranks m >= 0 gives the generating function used here. *)

BeginPackage["OEIS`"];

A064174::usage = "A064174[n] gives the number of partitions of n with nonnegative rank, Sum_{k>=1} (-1)^(k-1) p(n - k(3k-1)/2).";
A064174List::usage = "A064174List[nmax] gives {A064174[1], ..., A064174[nmax]}, computed by a recurrence in the sequence itself that needs no partition numbers.";

Begin["`Private`"];


(* ::Subsection:: *)
(*Generating function*)


(* ::Text:: *)
(*For m >= 0, Sum_{n>=1} N(m, n) x^n = Sum_{k>=1} (-1)^(k-1) x^(k(3k-1)/2 + m k) (1 - x^k) / Prod_{r>=1} (1 - x^r) (Atkin and Swinnerton-Dyer, (2.12), see A101198.wl). Summing over m >= 0, Sum_m x^(m k) = 1/(1 - x^k) cancels the factor 1 - x^k, so Sum_{n>=1} a(n) x^n = Sum_{k>=1} (-1)^(k-1) x^(k(3k-1)/2) / Prod_{r>=1} (1 - x^r).*)


(* ::Subsection:: *)
(*One term*)


(* ::Text:: *)
(*Reading off the coefficient of x^n gives a(n) = Sum_{k>=1} (-1)^(k-1) p(n - k(3k-1)/2), with p(j) = 0 for j < 0. The terms with the other pentagonal numbers k(3k+1)/2 sum to p(n) - a(n), the partitions with negative rank (A064173), which is Euler's pentagonal recurrence for p(n) split in two.*)


A064174[n_Integer?Positive] :=
  Sum[(-1)^(k - 1) PartitionsP[n - k (3 k - 1)/2], {k, 1, Floor[(Sqrt[24 n + 1] + 1)/6]}]


(* ::Subsection:: *)
(*Many terms*)


(* ::Text:: *)
(*Multiplying the generating function by Prod (1 - x^r) = Sum_{k} (-1)^k x^(k(3k-1)/2) (k over all integers) gives a(n) = Sum_{k>=1} (-1)^(k-1) (a(n - k(3k-1)/2) + a(n - k(3k+1)/2)) + e(n), with a(j) = 0 for j <= 0 and e(n) = (-1)^(k-1) when n = k(3k-1)/2, otherwise 0. Each term costs about Sqrt[8n/3] additions of earlier terms, which is much faster than PartitionsP for a whole list.*)


A064174List[nmax_Integer?Positive] :=
  Module[{a = ConstantArray[0, nmax], s, k, g},
    Do[
      s = 0; k = 1;
      While[(g = k (3 k - 1)/2) <= n,
        s += (-1)^(k - 1) (If[g == n, 1, a[[n - g]]] + If[n - g - k > 0, a[[n - g - k]], 0]);
        k++];
      a[[n]] = s,
      {n, nmax}];
    a]


(* ::Subsection:: *)
(*Invalid arguments*)


(* ::Text:: *)
(*Both functions give a message and return $Failed when n or nmax is not a positive integer; like the OEIS entry, the sequence starts at n = 1.*)


Scan[
  Function[f,
    MessageName[f, "posint"] = "`1` is not a positive integer.";
    f[n_] /; ! (IntegerQ[n] && n > 0) := (Message[f::posint, n]; $Failed)],
  {A064174, A064174List}]


End[];

EndPackage[];
