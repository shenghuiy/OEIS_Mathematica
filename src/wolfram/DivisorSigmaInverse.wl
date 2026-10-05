(* ::Package:: *)

(* Mathematica port of invsigmaDiv from invphi.gp (M. Alekseyev, https://github.com/maxale/gpscripts/blob/main/invphi.gp),
   based on: M. A. Alekseyev, "Computing the Inverses, their Power Sums, and Extrema for Euler's Totient and
   Other Multiplicative Functions", J. Integer Sequences 19 (2016), Article 16.5.2. *)

BeginPackage["OEIS`"];

invSigmaDivisors::usage = "invSigmaDivisors[n, k, u] returns a list, indexed like Divisors[n], whose j-th entry is the sorted list of all x <= u with DivisorSigma[k, x] equal to the j-th divisor of n. k defaults to 1 and u to Infinity.";
DivisorSigmaInverse::usage = "DivisorSigmaInverse[n, k, u] returns all x <= u with DivisorSigma[k, x] == n.";
DivisorSigmaInverseCount::usage = "DivisorSigmaInverseCount[n, k, u] returns the number of x <= u with DivisorSigma[k, x] == n, without building the list of solutions. k defaults to 1 and u to Infinity.";

Begin["`Private`"];


(* ::Subsection:: *)
(*Step 1: the menu of prime-power building blocks*)


(* ::Text:: *)
(*For each divisor d > 1 of n, find every prime p and exponent m with DivisorSigma[k, p^m] == d. Since p divides d - 1, it suffices to factor d - 1: set q = d (p^k - 1) + 1, which must be an exact power p^t with k | t, and then m = t/k - 1. The result is a list with one entry per prime p, each entry being a list of blocks {d, p^m}.*)


(* ::Text:: *)
(*oddPrimes[x] lists the prime factors of x (none for x = 1), the only candidates p since sigma_k(p^m) = 1 mod p. The test for a pair (d, p) is compiled for n < 2^62. It never forms q: it climbs s = sigma_k(p^m) = 1 + p^k + ... + p^(m k) term by term, stopping as soon as s reaches d, with every product guarded against overflow. Larger n use cookSigmaInterpreted, which does the same test with exact integers.*)


oddPrimes[x_Integer] := If[x == 1, {}, FactorInteger[x][[All, 1]]]

cookSigmaInterpreted[n_Integer, k_Integer?Positive] := Module[{blocks},
  blocks = Flatten[
    Table[
      With[{q = d (p^k - 1) + 1}, {t = IntegerExponent[q, p]},
        If[t > k && Divisible[t, k] && q == p^t, {p, {d, p^(t/k - 1)}}, Nothing]],
      {d, Rest[Divisors[n]]},
      {p, oddPrimes[d - 1]}],
    1];
  Values[GroupBy[blocks, First -> Last]]
]

(* Rows {p, d, p^m} for every pair (dd[[i]], pp[[i]]) with sigma_k(p^m) = d for some m >= 1, in input order, followed by a {0, 0, 0} row. *)
blockRows = FunctionCompile @ Function[{
    Typed[k, "MachineInteger"],
    Typed[dd, "PackedArray"["MachineInteger", 1]],
    Typed[pp, "PackedArray"["MachineInteger", 1]]},
  Module[{out, d, p, pk, e, s, term, pm, ok, rows, res},
    out = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    Do[
      d = dd[[i]];
      p = pp[[i]];
      pk = 1; e = 0; ok = True;
      While[e < k && ok,
        If[pk > Quotient[d, p], ok = False, pk = pk p; e = e + 1]];
      If[ok,
        s = 1 + pk; term = pk; pm = p;
        While[s < d && ok,
          If[term > Quotient[d, pk], ok = False,
            term = term pk; pm = pm p; s = s + term]];
        If[ok && s == d,
          out["Append", p]; out["Append", d]; out["Append", pm]]],
      {i, 1, Length[dd]}];
    rows = Quotient[out["Length"], 3];
    res = Table[0, {rows + 1}, {3}];   (* trailing {0, 0, 0} row keeps the array non-empty *)
    Do[
      res[[r, 1]] = out["Part", 3 r - 2];
      res[[r, 2]] = out["Part", 3 r - 1];
      res[[r, 3]] = out["Part", 3 r],
      {r, 1, rows}];
    res
  ]
];

cookSigma[n_Integer, k_Integer?Positive] := Module[{ds, primes, rows},
  If[n >= 2^62, Return[cookSigmaInterpreted[n, k]]];
  ds = Rest[Divisors[n]];
  primes = oddPrimes /@ (ds - 1);
  If[Total[Length /@ primes] == 0, Return[{}]];
  rows = Most @ blockRows[k,
    Developer`ToPackedArray[Flatten[MapThread[ConstantArray, {ds, Length /@ primes}]], Integer],
    Developer`ToPackedArray[Flatten[primes], Integer]];
  Values[GroupBy[rows, First -> Rest]]
]


(* ::Subsection:: *)
(*Step 2: dynamic programming over the divisors of n*)


(* ::Text:: *)
(*The table r[d] of the DP is stored flat: entry i is a pair (own[i], xs[i]) meaning "xs[i] has sigma_k equal to divs[[own[i]]]". Entries of the same owner are chained through nxt, with head[j] the newest entry of divs[[j]] (0 means none), so a block {d, q} only visits owners m that divide n/d. Unique factorization guarantees every x is produced exactly once, so no deduplication is needed. Processing a prime snapshots the current length cnt and skips entries beyond it, so each prime is used at most once. Every value is bounded by n, so machine integers cannot overflow when n < 2^62. If countOnly is True the result is the single row {nsol, 0} and sel is ignored. With no bound (u >= n) the DP then runs on counts alone: r[j] is the number of x with sigma_k(x) = divs[[j]], so no x is ever built. With a bound, entries owned by n itself (which are never extended) are counted in nsol instead of stored.*)


dpCompiled = FunctionCompile @ Function[{
    Typed[n, "MachineInteger"], Typed[u, "MachineInteger"],
    Typed[divs, "PackedArray"["MachineInteger", 1]],
    Typed[bd, "PackedArray"["MachineInteger", 1]],
    Typed[bq, "PackedArray"["MachineInteger", 1]],
    Typed[gstart, "PackedArray"["MachineInteger", 1]],
    Typed[sel, "MachineInteger"], Typed[countOnly, "Boolean"]},
  Module[{nd = Length[divs], ng = Length[gstart] - 1, rows = 0, j = 0, nsol = 0, r, t, res, own, xs, nxt, head, cnt, d, q, nd1, m, i, x, tgt, lo, hi, mid, len},
    own = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    xs = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    nxt = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
    head = Typed[CreateDataStructure["FixedArray", nd], "FixedArray"::["MachineInteger"]];
    own["Append", 1];
    xs["Append", 1];
    nxt["Append", 0];
    head["SetPart", 1, 1];
    If[countOnly && u >= n,
      r = Typed[CreateDataStructure["FixedArray", nd], "FixedArray"::["MachineInteger"]];
      t = Typed[CreateDataStructure["FixedArray", nd], "FixedArray"::["MachineInteger"]];
      r["SetPart", 1, 1];
      Do[
        Do[t["SetPart", j, r["Part", j]], {j, 1, nd}];
        Do[
          d = bd[[b]];
          nd1 = Quotient[n, d];
          Do[
            m = divs[[j]];
            If[Mod[nd1, m] == 0 && r["Part", j] != 0,
              tgt = m d;
              lo = 1; hi = nd;
              While[lo < hi,
                mid = Quotient[lo + hi, 2];
                If[divs[[mid]] < tgt, lo = mid + 1, hi = mid]];
              t["SetPart", lo, t["Part", lo] + r["Part", j]]],
            {j, 1, nd}],
          {b, gstart[[g]], gstart[[g + 1]] - 1}];
        Do[r["SetPart", j, t["Part", j]], {j, 1, nd}],
        {g, 1, ng}];
      nsol = r["Part", nd],
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
                    If[countOnly && lo == nd,
                      nsol = nsol + 1,
                      own["Append", lo];
                      xs["Append", x];
                      nxt["Append", head["Part", lo]];
                      head["SetPart", lo, xs["Length"]]]]];
                i = nxt["Part", i]]],
            {j, 1, nd}],
          {b, gstart[[g]], gstart[[g + 1]] - 1}],
        {g, 1, ng}]];
    len = xs["Length"];
    If[countOnly,
      res = Table[0, {1}, {2}];
      res[[1, 1]] = nsol,
      Do[If[sel == 0 || own["Part", i] == sel, rows = rows + 1], {i, 1, len}];
      res = Table[0, {rows + 1}, {2}];   (* trailing {0, 0} row keeps the array non-empty *)
      Do[
        If[sel == 0 || own["Part", i] == sel,
          j = j + 1;
          res[[j, 1]] = own["Part", i];
          res[[j, 2]] = xs["Part", i]],
        {i, 1, len}]];
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

(* Runs the compiled DP. With countOnly = False, sel = 0 returns all (divisor index, x) pairs and sel = j only those owned
   by divs[[j]], followed by a {0, 0} row that callers drop with Most; with countOnly = True it returns {{count, 0}}. *)
runDP[n_Integer, k_Integer, u_, divs_List, sel_Integer, countOnly_] := Module[{groups = cookSigma[n, k]},
  dpCompiled[n, Min[u, n],   (* x <= sigma_k(x)^(1/k) <= n *)
    Developer`ToPackedArray[divs, Integer],
    Developer`ToPackedArray[Flatten[groups[[All, All, 1]]], Integer],
    Developer`ToPackedArray[Flatten[groups[[All, All, 2]]], Integer],
    Developer`ToPackedArray[Prepend[1 + Accumulate[Length /@ groups], 1], Integer],
    sel, countOnly]
]

invSigmaDivisors[n_Integer?Positive, Optional[k_Integer?Positive, 1], u_ : Infinity] := Module[{divs, pairs},
  If[n == 1, Return[{{1}}]];
  If[n >= 2^62, Return[invSigmaDivisorsInterpreted[n, k, u]]];
  divs = Divisors[n];
  pairs = Sort[Most @ runDP[n, k, u, divs, 0, False]];   (* packed lexicographic sort: by owner, then by x *)
  TakeList[pairs[[All, 2]], BinCounts[pairs[[All, 1]], {1, Length[divs] + 1, 1}]]
]

DivisorSigmaInverse[n_Integer?Positive, Optional[k_Integer?Positive, 1], u_ : Infinity] := Module[{divs},
  If[n == 1, Return[{1}]];
  If[n >= 2^62, Return[Last[invSigmaDivisorsInterpreted[n, k, u]]]];
  divs = Divisors[n];
  Sort[Most[runDP[n, k, u, divs, Length[divs], False]][[All, 2]]]
]

DivisorSigmaInverseCount[n_Integer?Positive, Optional[k_Integer?Positive, 1], u_ : Infinity] :=
  Which[
    n == 1, 1,
    n >= 2^62, Length[Last[invSigmaDivisorsInterpreted[n, k, u]]],
    True, runDP[n, k, u, Divisors[n], 0, True][[1, 1]]]


End[];

EndPackage[];
