(* ::Package:: *)

(* A401118 by integer linear programming, solved with SCIP: the size of the largest subset of {1..n} with no 3-element subset whose pairwise LCMs are all equal (Erdos problem #536). The OEIS entry's b-file (n <= 656) was computed with ILP solvers. SCIP is called through ForeignFunctionLoad on the C wrapper in src/c/a401118_scip; without that library the same program goes to LinearOptimization. A401118.wl has the exhaustive search, which stops being practical past n = 30. *)

BeginPackage["OEIS`"];

A401118SCIP::usage = "A401118SCIP[n] gives the size of the largest subset of {1..n} having no 3-element subset {x, y, z} with lcm(x, y) = lcm(y, z) = lcm(z, x), by solving an integer linear program. A401118SCIP[n, \"Subset\"] gives one such subset of that size, and A401118SCIP[n, \"Size\"] is the same as A401118SCIP[n]. The option Method -> Automatic, \"SCIP\" or \"LinearOptimization\" picks the solver; Automatic uses SCIP when its library (built from src/c/a401118_scip) is found.";

Begin["`Private`"];


(* The SCIP library is looked up relative to this file, so remember where it was loaded from *)

a401118SCIPPackageDirectory = DirectoryName[$InputFileName];


(* ::Subsection:: *)
(*LCM cliques*)


(* ::Text:: *)
(*In an LCM triangle {x, y, z} all three pairs have the same LCM L. So group the pairs of {1..n} by their LCM, and for each L draw the graph whose edges are the pairs with that LCM: the LCM triangles are exactly the triangles of these graphs. Any three numbers in a clique of one graph form an LCM triangle, so a valid subset takes at most two numbers from each clique. a401118SCIPCliques lists the maximal cliques of 3 or more vertices, each sorted; every LCM triangle lies in one of them. Example: 6, 10, 15, 30 have pairwise LCM 30.*)


a401118SCIPCliques[n_Integer?NonNegative] :=
  Module[{groups},
    groups = Select[GroupBy[Subsets[Range[n], {2}], Apply[LCM] -> Identity], Length[#] >= 3 &];
    Join @@ Values@Map[
      Sort /@ Select[FindClique[Graph[UndirectedEdge @@@ #], Infinity, All], Length[#] >= 3 &] &,
      groups]]


(* ::Subsection:: *)
(*The integer linear program*)


(* ::Text:: *)
(*One 0/1 variable per number that is in some clique: maximize their sum subject to Total[clique] <= 2 for every clique. The numbers in no clique are always taken. One constraint per maximal clique instead of one per triangle gives a tighter LP relaxation. A solver is a function solve[vars, cliques] that returns the vars set to 1; a401118SCIPSet[n, solve] returns an optimal subset.*)


a401118SCIPSet[n_Integer?NonNegative, solve_] :=
  Module[{cliques = a401118SCIPCliques[n], vars},
    If[cliques === {}, Return[Range[n], Module]];
    vars = Union @@ cliques;
    Union[Complement[Range[n], vars], solve[vars, cliques]]]

(* The LinearOptimization solver, used by Method -> "LinearOptimization" and whenever SCIP is missing or fails *)

a401118LPSolve[vars_List, cliques_List] := Module[{x, sol},
  sol = LinearOptimization[-Total[x /@ vars],
    Join[Total[x /@ #] <= 2 & /@ cliques, Thread[0 <= x /@ vars <= 1]],
    (x /@ vars) \[Element] Integers];
  Select[vars, Round[x[#] /. sol] == 1 &]]


(* ::Subsection:: *)
(*SCIP through ForeignFunctionLoad*)


(* ::Text:: *)
(*src/c/a401118_scip/a401118_scip.c solves the same program with SCIP's C API. Its CMake build puts a401118_scip.dll (.so, .dylib) in build/ at the repository root, together with SCIP's own DLLs on Windows; the environment variable A401118_SCIP_LIB can name another directory. Windows resolves a DLL's dependencies on PATH rather than next to it, so LibraryLoad loads SoPlex and SCIP from that directory first. The library is looked for once per session; a failed lookup is remembered too.*)


(* ::Text:: *)
(*The model is passed as flat arrays: weights (all 1), and the cliques in compressed form, start offsets plus 0-based variable indices. The function returns the optimum, or a negative error code, and writes the 0/1 solution into an output array.*)


a401118SCIPDirectory[] := With[{env = Environment["A401118_SCIP_LIB"]},
  If[StringQ[env], env, FileNameJoin[{a401118SCIPPackageDirectory, "..", "..", "build"}]]]

a401118SCIPFunction[] := a401118SCIPFunction[] = Module[{dir = a401118SCIPDirectory[], lib, f},
  lib = FileNameJoin[{dir, "a401118_scip" <> Switch[$OperatingSystem, "Windows", ".dll", "MacOSX", ".dylib", _, ".so"]}];
  If[! FileExistsQ[lib], Return[$Failed, Module]];
  If[$OperatingSystem === "Windows",
   Scan[Quiet[LibraryLoad[#]] &, Join[FileNames["libsoplex*.dll", dir], FileNames["libscip*.dll", dir]]]];
  f = Quiet[ForeignFunctionLoad[lib, "a401118_scip_max",
     {"CInt", "RawPointer"::["CDouble"], "CInt", "RawPointer"::["CInt"], "RawPointer"::["CInt"], "CDouble", "RawPointer"::["CInt"]} -> "CInt"]];
  If[Head[f] === ForeignFunction, f, $Failed]]

(* Same contract as a401118LPSolve. On a SCIP error code it gives A401118SCIP::scipfail and solves the problem with a401118LPSolve instead. *)

a401118SCIPSolve[f_][vars_List, cliques_List] := Module[{pos, idx, start, out, val},
  pos = AssociationThread[vars -> Range[0, Length[vars] - 1]];
  idx = Flatten[Lookup[pos, #] & /@ cliques];
  start = Prepend[Accumulate[Length /@ cliques], 0];
  out = RawMemoryAllocate["CInt", Length[vars]];
  val = f[Length[vars], RawMemoryExport[ConstantArray[1., Length[vars]], "CDouble"], Length[cliques],
    RawMemoryExport[start, "CInt"], RawMemoryExport[If[idx === {}, {0}, idx], "CInt"], 0., out];
  If[val < 0,
   Message[A401118SCIP::scipfail, val]; a401118LPSolve[vars, cliques],
   Pick[vars, RawMemoryImport[out, {"List", Length[vars]}], 1]]]


(* ::Subsection:: *)
(*Choosing the solver*)


(* a401118SCIPSolver[method] gives the solve function, or $Failed after a message *)

a401118SCIPSolver["LinearOptimization"] := a401118LPSolve

a401118SCIPSolver[method : Automatic | "SCIP"] := With[{f = a401118SCIPFunction[]},
  Which[
   f =!= $Failed, a401118SCIPSolve[f],
   method === Automatic, a401118LPSolve,
   True, Message[A401118SCIP::noscip, a401118SCIPDirectory[]]; $Failed]]

a401118SCIPSolver[method_] := (Message[A401118SCIP::method, method]; $Failed)


(* ::Subsection:: *)
(*Public function*)


Options[A401118SCIP] = {Method -> Automatic};

A401118SCIP[n_Integer?Positive, opts : OptionsPattern[]] := A401118SCIP[n, "Size", opts]

A401118SCIP[n_Integer?Positive, prop : "Size" | "Subset", opts : OptionsPattern[]] :=
  With[{solve = a401118SCIPSolver[OptionValue[Method]]},
   Which[
    solve === $Failed, $Failed,
    prop === "Subset", a401118SCIPSet[n, solve],
    True, Length[a401118SCIPSet[n, solve]]]]


(* ::Subsection:: *)
(*Messages*)


A401118SCIP::posint = "`1` is not a positive integer.";
A401118SCIP::prop = "`1` is not \"Size\" or \"Subset\".";
A401118SCIP::method = "Method -> `1` is not Automatic, \"SCIP\" or \"LinearOptimization\".";
A401118SCIP::noscip = "Method -> \"SCIP\" needs the library built from src/c/a401118_scip; none was found in `1`.";
A401118SCIP::scipfail = "SCIP returned error code `1`; solving with LinearOptimization instead.";

A401118SCIP[n_, OptionsPattern[]] /; ! (IntegerQ[n] && n > 0) := (Message[A401118SCIP::posint, n]; $Failed)
A401118SCIP[n_, _String, OptionsPattern[]] /; ! (IntegerQ[n] && n > 0) := (Message[A401118SCIP::posint, n]; $Failed)
A401118SCIP[n_Integer?Positive, prop : Except[_?OptionQ], OptionsPattern[]] := (Message[A401118SCIP::prop, prop]; $Failed)


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Benchmark*)


(* ::Text:: *)
(*Windows 11, Mathematica 15.0.1, SCIP 10.1.0 built as in docs/A401118_SCIP.md. Every value matches the OEIS b-file.*)


(* ::Program:: *)
(*n     a(n)   SCIP     LinearOptimization*)
(*100   76     0.07 s   0.16 s*)
(*200   146    1.8 s    3.7 s*)
(*300   218    5.2 s    13.5 s*)
(*400   290    12.1 s   40.1 s*)
(*500   356    38.3 s*)
(*656   464    365 s*)
