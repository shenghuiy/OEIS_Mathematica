(* ::Package:: *)

(* Size of the largest subset of {1..n} with no 3-element subset whose pairwise LCMs are all equal (Erdos problem #536). A compiled exhaustive search: for k = n, n - 1, ..., it walks the k-subsets of {1..n} one at a time and stops at the first one with no such triple. *)

BeginPackage["OEIS`"];

A401118::usage = "A401118[n] gives the size of the largest subset of {1..n} having no 3-element subset {x, y, z} with lcm(x, y) = lcm(y, z) = lcm(z, x).";

Begin["`Private`"];


(* ::Subsection:: *)
(*LCM triangles*)


(* ::Text:: *)
(*Call {x, y, z} an LCM triangle when lcm(x, y) = lcm(y, z) = lcm(z, x). The smallest is {2, 3, 6}, so a(n) = n for n <= 5 and a(6) = 5. a401118GoodQ tests a sorted subset by trying all of its triples; it returns False at the first LCM triangle.*)


a401118GoodQDecl = FunctionDeclaration[a401118GoodQ,
  Typed[{"PackedArray"::["MachineInteger", 1]} -> "Boolean"]@
  Function[{s},
    Module[{k = Length[s], ok = True, x, y, z, l},
      Do[
        x = s[[i]]; y = s[[j]]; z = s[[m]]; l = LCM[x, y];
        If[LCM[y, z] == l && LCM[z, x] == l, ok = False; Break[]],
        {i, 1, k - 2}, {j, i + 1, k - 1}, {m, j + 1, k}];
      ok]]];


(* ::Subsection:: *)
(*k-subsets, one at a time*)


(* ::Text:: *)
(*IncrementalObject["Subsets"] does not compile, so a401118KSubsets is a compiled IncrementalFunction that yields the k-subsets of {1..n} in the order of Subsets[Range[n], {k}]. Each IncrementalYield pauses it; the next subset comes from adding 1 to the rightmost entry that can still grow and resetting the entries after it to consecutive values. Compiled code consumes it as an iterator, Do[..., {s, a401118KSubsets[n, k]}], so no list of subsets is ever built.*)


a401118KSubsetsDecl = FunctionDeclaration[a401118KSubsets,
  Typed[{"MachineInteger", "MachineInteger"} ->
    "IncrementalFunction"["PackedArray"::["MachineInteger", 1], "Null"]]@
  IncrementalFunction@Function[{n, k},
    Module[{c = Range[k], i = k},
      While[True,
        IncrementalYield[c];
        i = k;
        While[i >= 1 && c[[i]] == n - k + i, i--];
        If[i == 0, Break[]];
        c[[i]] += 1;
        Do[c[[j]] = c[[j - 1]] + 1, {j, i + 1, k}]]]]];


(* ::Subsection:: *)
(*Search*)


(* ::Text:: *)
(*a401118Search tries k = n, n - 1, ... and returns the first k with a k-subset free of LCM triangles. The search is exponential in n: n = 24 takes under a second, n = 28 about 3.5 s and n = 30 about 27 s.*)


a401118Search = FunctionCompile[{a401118KSubsetsDecl, a401118GoodQDecl},
  Function[Typed[n, "MachineInteger"],
    Module[{res = 0, k = n},
      While[k >= 1 && res == 0,
        Do[If[a401118GoodQ[s], res = k; Break[]], {s, a401118KSubsets[n, k]}];
        k--];
      res]]];


(* ::Text:: *)
(*The same search with the built-in IncrementalObject["Subsets"] (Mathematica 15.0) as the iterator, run at top level, with only the triangle test compiled. It is about as fast, and the tests use it as an independent check of a401118KSubsets.*)


a401118GoodC = FunctionCompile[a401118GoodQDecl,
  Function[Typed[s, "PackedArray"::["MachineInteger", 1]], a401118GoodQ[s]]];

a401118SearchIncremental[n_Integer?NonNegative] :=
  SelectFirst[Range[n, 1, -1],
    Module[{found = False},
      Do[If[a401118GoodC[s], found = True; Break[]],
        {s, IncrementalObject["Subsets"][Range[n], {#}]}];
      found] &,
    0]


A401118[n_Integer?Positive] := a401118Search[n]


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Benchmark*)


(* ::Text:: *)
(*Windows 11, Mathematica 15.0.1, wolframscript. The pure version is SelectFirst[Range[n, 1, -1], AnyTrue[Subsets[Range[n], {#}], NoneTrue[Subsets[#, {3}], Equal @@ LCM @@@ Subsets[#, {2}] &] &] &, 0].*)


(* ::Program:: *)
(*n    A401118   a401118SearchIncremental   pure*)
(*20   0.041 s   0.13 s                     2.17 s*)
(*22   0.094 s   0.11 s                     4.32 s*)
(*24   0.72 s    0.80 s                     28.95 s*)
