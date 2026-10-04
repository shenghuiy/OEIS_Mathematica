(* ::Package:: *)

(* Mathematica port of invsigmaDiv from invphi.gp (M. Alekseyev, https://github.com/maxale/gpscripts/blob/main/invphi.gp),
   based on: M. A. Alekseyev, "Computing the Inverses, their Power Sums, and Extrema for Euler's Totient and
   Other Multiplicative Functions", J. Integer Sequences 19 (2016), Article 16.5.2. *)

BeginPackage["OEIS`"];

invSigmaDivisors::usage = "invSigmaDivisors[n, k, u] returns a list, indexed like Divisors[n], whose j-th entry is the sorted list of all x <= u with DivisorSigma[k, x] equal to the j-th divisor of n. k defaults to 1 and u to Infinity.";
DivisorSigmaInverse::usage = "DivisorSigmaInverse[n, k, u] returns all x <= u with DivisorSigma[k, x] == n.";

Begin["`Private`"];


(* ::Subsection:: *)
(*Step 1: the menu of prime-power building blocks*)


(* ::Text:: *)
(*For each divisor d > 1 of n, find every prime p and exponent m with DivisorSigma[k, p^m] == d. Since p divides d - 1, it suffices to factor d - 1: set q = d (p^k - 1) + 1, which must be an exact power p^t with k | t, and then m = t/k - 1. The result is a list with one entry per prime p, each entry being a list of blocks {d, p^m}.*)


cookSigma[n_Integer, k_Integer?Positive] := Module[{blocks},
  blocks = Flatten[
    Table[
      With[{q = d (p^k - 1) + 1}, {t = IntegerExponent[q, p]},
        If[t > k && Divisible[t, k] && q == p^t, {p, {d, p^(t/k - 1)}}, Nothing]],
      {d, Rest[Divisors[n]]},
      {p, Select[First /@ FactorInteger[d - 1], # > 1 &]}],
    1];
  Values[GroupBy[blocks, First -> Last]]
]


(* ::Subsection:: *)
(*Step 2: dynamic programming over the divisors of n*)


(* ::Text:: *)
(*The table r[d] of the DP is stored flat: entry i is a pair (own[i], xs[i]) meaning "xs[i] has sigma_k equal to divs[[own[i]]]". Entries of the same owner are chained through nxt, with head[j] the newest entry of divs[[j]] (0 means none), so a block {d, q} only visits owners m that divide n/d. Unique factorization guarantees every x is produced exactly once, so no deduplication is needed. Processing a prime snapshots the current length cnt and skips entries beyond it, so each prime is used at most once. Every value is bounded by n, so machine integers cannot overflow when n < 2^62.*)


dpCompiled = FunctionCompile @ Function[{
    Typed[n, "MachineInteger"], Typed[u, "MachineInteger"],
    Typed[divs, "PackedArray"["MachineInteger", 1]],
    Typed[bd, "PackedArray"["MachineInteger", 1]],
    Typed[bq, "PackedArray"["MachineInteger", 1]],
    Typed[gstart, "PackedArray"["MachineInteger", 1]],
    Typed[sel, "MachineInteger"]},
  Module[{nd = Length[divs], ng = Length[gstart] - 1, rows = 0, j = 0, res, own, xs, nxt, head, cnt, d, q, nd1, m, i, x, tgt, lo, hi, mid, len},
    own = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    xs = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    nxt = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    head = Typed[CreateDataStructure["FixedArray", nd], "FixedArray"::["MachineInteger"]];
    own["Append", 1];
    xs["Append", 1];
    nxt["Append", 0];
    head["SetPart", 1, 1];
    Do[
      cnt = xs["Length"];
      Do[
        d = bd[[b]];
        q = bq[[b]];
        nd1 = Quotient[n, d];
        Do[
          m = divs[[j]];
          If[Mod[nd1, m] == 0 && head["Part", j] != 0,
            tgt = m d;
            lo = 1; hi = nd;
            While[lo < hi,
              mid = Quotient[lo + hi, 2];
              If[divs[[mid]] < tgt, lo = mid + 1, hi = mid]];
            i = head["Part", j];
            While[i != 0,
              If[i <= cnt,
                x = xs["Part", i] q;
                If[x <= u,
                  own["Append", lo];
                  xs["Append", x];
                  nxt["Append", head["Part", lo]];
                  head["SetPart", lo, xs["Length"]]]];
              i = nxt["Part", i]]],
          {j, 1, nd}],
        {b, gstart[[g]], gstart[[g + 1]] - 1}],
      {g, 1, ng}];
    len = xs["Length"];
    Do[If[sel == 0 || own["Part", i] == sel, rows = rows + 1], {i, 1, len}];
    res = Table[0, {rows + 1}, {2}];   (* trailing {0, 0} row keeps the array non-empty *)
    Do[
      If[sel == 0 || own["Part", i] == sel,
        j = j + 1;
        res[[j, 1]] = own["Part", i];
        res[[j, 2]] = xs["Part", i]],
      {i, 1, len}];
    res
  ]
];


(* ::Text:: *)
(*Original association-based DP, kept for n >= 2^62 where machine integers could overflow.*)


invSigmaDivisorsInterpreted[n_Integer?Positive, k_Integer?Positive, u_] := Module[{divs, r, t},
  divs = Divisors[n];
  r = AssociationMap[{} &, divs];
  r[1] = {1};
  Do[
    t = r;
    Do[
      With[{d = block[[1]], q = block[[2]]},
        Do[
          t[m d] = Union[t[m d], Select[r[m] q, # <= u &]],
          {m, Divisors[n/d]}]],
      {block, primeBlocks}];
    r = t,
    {primeBlocks, cookSigma[n, k]}];
  Lookup[r, divs]
]

(* Runs the compiled DP; sel = 0 returns all (divisor index, x) pairs, sel = j only those owned by divs[[j]]. *)
sigmaPairs[n_Integer, k_Integer, u_, divs_List, sel_Integer] := Module[{groups = cookSigma[n, k]},
  Most @ dpCompiled[n, Min[u, n],   (* x <= sigma_k(x)^(1/k) <= n *)
    Developer`ToPackedArray[divs, Integer],
    Developer`ToPackedArray[Flatten[groups[[All, All, 1]]], Integer],
    Developer`ToPackedArray[Flatten[groups[[All, All, 2]]], Integer],
    Developer`ToPackedArray[Prepend[1 + Accumulate[Length /@ groups], 1], Integer],
    sel]
]

invSigmaDivisors[n_Integer?Positive, Optional[k_Integer?Positive, 1], u_ : Infinity] := Module[{divs, pairs},
  If[n == 1, Return[{{1}}]];
  If[n >= 2^62, Return[invSigmaDivisorsInterpreted[n, k, u]]];
  divs = Divisors[n];
  pairs = Sort[sigmaPairs[n, k, u, divs, 0]];   (* packed lexicographic sort: by owner, then by x *)
  TakeList[pairs[[All, 2]], BinCounts[pairs[[All, 1]], {1, Length[divs] + 1, 1}]]
]

DivisorSigmaInverse[n_Integer?Positive, Optional[k_Integer?Positive, 1], u_ : Infinity] := Module[{divs},
  If[n == 1, Return[{1}]];
  If[n >= 2^62, Return[Last[invSigmaDivisorsInterpreted[n, k, u]]]];
  divs = Divisors[n];
  Sort[sigmaPairs[n, k, u, divs, Length[divs]][[All, 2]]]
]


End[];

EndPackage[];
