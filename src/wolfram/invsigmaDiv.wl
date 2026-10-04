(* ::Package:: *)

(* Mathematica port of invsigmaDiv from invphi.gp (M. Alekseyev, https://github.com/maxale/gpscripts/blob/main/invphi.gp),
   based on: M. A. Alekseyev, "Computing the Inverses, their Power Sums, and Extrema for Euler's Totient and
   Other Multiplicative Functions", J. Integer Sequences 19 (2016), Article 16.5.2. *)

BeginPackage["OEIS`"];

invSigmaDivisors::usage = "invSigmaDivisors[n, k, u] returns a list, indexed like Divisors[n], whose j-th entry is the sorted list of all x <= u with DivisorSigma[k, x] equal to the j-th divisor of n. k defaults to 1 and u to Infinity.";
invSigma::usage = "invSigma[n, k, u] returns all x <= u with DivisorSigma[k, x] == n.";

Begin["`Private`"];


(* ::Subsection:: *)
(*Step 1: the menu of prime-power building blocks*)


(* ::Text:: *)
(*For each divisor d > 1 of n, find every prime p and exponent m with DivisorSigma[k, p^m] == d. Since p divides d - 1, it suffices to factor d - 1: set q = d (p^k - 1) + 1, which must be an exact power p^t with k | t, and then m = t/k - 1. The result is a list with one entry per prime p, each entry being a list of blocks {d, p^m}.*)


cookSigma[n_Integer, k_Integer?Positive] := Module[{blocks},
  blocks = Flatten[
    Table[
      With[{q = d (p^k - 1) + 1},
        With[{t = IntegerExponent[q, p]},
          If[t > k && Divisible[t, k] && q == p^t, {p, {d, p^(t/k - 1)}}, Nothing]]],
      {d, Rest[Divisors[n]]},
      {p, Select[First /@ FactorInteger[d - 1], # > 1 &]}],
    1];
  Values[GroupBy[blocks, First -> Last]]
]


(* ::Subsection:: *)
(*Step 2: dynamic programming over the divisors of n*)


(* ::Text:: *)
(*r[d] holds every x built from the primes processed so far with sigma_k(x) = d. Processing a prime starts from a copy t of r ("use no power of p") and, for each block {d, q}, adds r[m] q into t[m d] for every m with m d | n. Reading from r and writing to t uses each prime at most once.*)


invSigmaDivisors[n_Integer?Positive, k_Integer?Positive : 1, u_ : Infinity] := Module[{divs, r, t},
  If[n == 1, Return[{{1}}]];
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

invSigma[n_Integer?Positive, k_Integer?Positive : 1, u_ : Infinity] := Last[invSigmaDivisors[n, k, u]]


End[];

EndPackage[];
