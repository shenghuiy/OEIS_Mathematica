(* ::Package:: *)

(* A401118: the size of the largest subset of {1..n} with no three elements whose pairwise LCMs are all equal (Erdos problem 536). The triangles come from prime exponents, and the terms are found one at a time, each where needed as a 0-1 program solved by LinearOptimization. A401118_SCIP.wl adds SCIP as a faster solver. *)

BeginPackage["OEIS`"];

A401118Incremental::usage = "A401118Incremental[n] gives the size of the largest subset of {1, ..., n} that contains no LCM triangle: no three elements i, j, k with lcm(i, j) = lcm(j, k) = lcm(k, i).";
A401118List::usage = "A401118List[nmax] gives {a(1), ..., a(nmax)} for A401118.";
LCMTriangles::usage = "LCMTriangles[n] gives every LCM triangle {i, j, k} with i < j < k <= n and lcm(i, j) = lcm(j, k) = lcm(k, i), sorted by k and then i.";
LCMTriangleFreeSubset::usage = "LCMTriangleFreeSubset[n] gives a largest subset of {1, ..., n} with no LCM triangle, of size A401118Incremental[n].";

Begin["`Private`"];


(* ::Subsection:: *)
(*LCM triangles from prime exponents*)


(* ::Text:: *)
(*lcm(i, j) = lcm(j, k) = lcm(k, i) = L exactly when, for every prime p, the largest exponent of p among i, j, k occurs at least twice. Fix the largest element m and a smaller one i, with G = gcd(i, m) and L = lcm(i, m). A prime divides r = L/G exactly when its exponents in i and m differ, and then the third element k must carry the larger exponent; where they are equal (to e), k can carry any exponent up to e. So k = A d, where g is the part of G coprime to r, A = L/g, and d divides g. If A >= m, no k < m exists.*)


(* ::Text:: *)
(*The coprime part loop: d = gcd(g, r) holds every prime of r that divides g, so dividing g by d and taking d = gcd(g, d) again strips those primes completely. The compiled function returns the triangles flattened, three integers each, for largest elements lo to hi.*)


lcmTrianglesC = FunctionCompile@Function[{Typed[lo, "MachineInteger"], Typed[hi, "MachineInteger"]},
  Module[{res, G, L, r, g, d, A, k},
   res = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::["MachineInteger"]];
   Do[Do[
     G = GCD[i, m]; L = Quotient[i, G] m; r = Quotient[L, G];
     g = G; d = GCD[g, r];
     While[d > 1, g = Quotient[g, d]; d = GCD[g, d]];
     A = Quotient[L, g];
     If[A < m,
      Do[If[Mod[g, j] == 0, k = A j;
        If[k > i, res["Append", i]; res["Append", k]; res["Append", m]]], {j, 1, Quotient[m - 1, A]}]],
     {i, 1, m - 1}], {m, lo, hi}];
   res["Elements"]]];


lcmTrianglesTop[lo_, hi_] := Partition[lcmTrianglesC[lo, hi], 3]


(* ::Subsection:: *)
(*One term at a time*)


(* ::Text:: *)
(*a(m) is a(m-1) or a(m-1) + 1, so each term asks one yes/no question: is there a triangle-free subset of {1..m} of size a(m-1) + 1? Such a subset must contain m, and the only new triangles are those with largest element m. The steps, keeping a witness S for a(m-1):*)


(* ::ItemNumbered:: *)
(*If no new triangle has both its smaller elements in S, then S + {m} is triangle-free, and a(m) = a(m-1) + 1 with no solve. This covers every m in no triangle at all, such as 1 and the primes.*)


(* ::ItemNumbered:: *)
(*Otherwise LinearOptimization maximizes the sum of 0-1 values x(v) over the numbers that are in some triangle; numbers in no triangle can always be added, so they get no variable. If the maximum plus their count reaches a(m-1) + 1, the solution is the new witness; otherwise a(m) = a(m-1) and S stays.*)


(* ::Text:: *)
(*The constraints are cliques rather than single triangles. Every triangle with largest element m and smaller element i has the same LCM L = lcm(i, m) on all three pairs, so the triangles with LCM L are the triples of a graph whose edges are pairs with LCM L. In a clique of that graph every three elements form a triangle, so at most two can be kept: one constraint sum <= 2 per maximal clique replaces all its triangles, and the LP bound is tighter. Example: 6, 10, 15, 30 have pairwise LCM 30. Only the cliques of the LCMs that gained a triangle are recomputed at each step. On the m = 198 problem (173 variables, 857 triangles, 721 cliques, 51 of them of size 4) maximizing with cliques takes 3.7 s, against 7.6 s for the feasibility problem with triangles.*)


lcmCliques[tris_List] := Select[
  FindClique[Graph[Union @@ (UndirectedEdge @@@ Subsets[#, {2}] & /@ tris)], Infinity, All],
  Length[#] >= 3 &]

lcmTriangleMax[vars_List, cliques_List] := Module[{x, sol},
  sol = Quiet@LinearOptimization[-Total[x /@ vars],
     Join[Table[0 <= x[v] <= 1, {v, vars}], Total[x /@ #] <= 2 & /@ cliques],
     Table[x[v] \[Element] Integers, {v, vars}], "PrimalMinimizerRules"];
  Select[vars, Round[x[#] /. sol] == 1 &]]


(* Returns {{a(1), ..., a(nmax)}, a largest triangle-free subset of {1..nmax}}; solve[vars, cliques] gives the elements of vars kept in an optimal solution *)

a401118Run[nmax_Integer, solve_] := Module[{a = 0, inS = <||>, inT = <||>, byL = <||>, cliques = <||>, terms, new, vars, w},
  terms = Table[
    new = lcmTrianglesTop[m, m];
    Scan[(inT[#] = True) &, Flatten[new]];
    Scan[(byL[LCM[#[[1]], #[[3]]]] = Append[Lookup[byL, LCM[#[[1]], #[[3]]], {}], #]) &, new];
    Scan[(cliques[#] = lcmCliques[byL[#]]) &, Union[LCM[#[[1]], #[[3]]] & /@ new]];
    If[NoneTrue[new, KeyExistsQ[inS, #[[1]]] && KeyExistsQ[inS, #[[2]]] &],
     a++; inS[m] = True,
     vars = Select[Range[m], KeyExistsQ[inT, #] &];
     w = solve[vars, Join @@ Values[cliques]];
     If[Length[w] + m - Length[vars] > a,
      a++;
      inS = AssociationThread[Join[w, Select[Range[m], ! KeyExistsQ[inT, #] &]] -> True]]];
    a, {m, nmax}];
  {terms, Sort[Keys[inS]]}]


(* ::Subsection:: *)
(*Public functions*)


(* The solver for calls without options; A401118_SCIP.wl replaces this definition (same left-hand side) with its Method -> Automatic choice *)

a401118DefaultSolver[head_] := lcmTriangleMax


LCMTriangles[n_Integer?Positive] := lcmTrianglesTop[1, n]

A401118List[nmax_Integer?Positive] := First[a401118Run[nmax, a401118DefaultSolver[A401118List]]]

A401118Incremental[n_Integer?Positive] := Last[A401118List[n]]

LCMTriangleFreeSubset[n_Integer?Positive] := Last[a401118Run[n, a401118DefaultSolver[LCMTriangleFreeSubset]]]


(* ::Subsection:: *)
(*Invalid arguments*)


Scan[
  Function[f,
    MessageName[f, "posint"] = "`1` is not a positive integer.";
    f[n_] /; ! (IntegerQ[n] && n > 0) := (Message[f::posint, n]; $Failed)],
  {A401118Incremental, A401118List, LCMTriangles, LCMTriangleFreeSubset}]


End[];

EndPackage[];
