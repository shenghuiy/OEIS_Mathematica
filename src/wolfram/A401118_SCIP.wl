(* ::Package:: *)

(* SCIP for the A401118 integer programs: a Method option on A401118ILP (A401118ILP.wl) and on A401118Incremental, A401118List and LCMTriangleFreeSubset (A401118Incremental.wl). It solves their 0-1 programs with SCIP (src/c/a401118_scip, through ForeignFunctionLoad) or leaves them to the packages' own LinearOptimization code. Everything about SCIP is in this file; the two packages are not changed, and are loaded first when they are not loaded yet. *)

If[DownValues[OEIS`Private`a401118ILPSet] === {}, Get[FileNameJoin[{DirectoryName[$InputFileName], "A401118ILP.wl"}]]];
If[DownValues[OEIS`Private`a401118Run] === {}, Get[FileNameJoin[{DirectoryName[$InputFileName], "A401118Incremental.wl"}]]];

BeginPackage["OEIS`"];

A401118ILP::usage = "A401118ILP[n] gives the size of the largest subset of {1..n} having no 3-element subset {x, y, z} with lcm(x, y) = lcm(y, z) = lcm(z, x), by solving an integer linear program. The option Method -> Automatic, \"SCIP\" or \"LinearOptimization\" picks the solver; Automatic uses SCIP when its library is found.";
A401118Incremental::usage = "A401118Incremental[n] gives A401118(n), the size of the largest subset of {1, ..., n} that contains no LCM triangle, computing the terms one at a time. It takes the same Method option as A401118ILP.";
A401118List::usage = "A401118List[nmax] gives {a(1), ..., a(nmax)} for A401118. It takes the same Method option as A401118ILP.";
LCMTriangleFreeSubset::usage = "LCMTriangleFreeSubset[n] gives a largest subset of {1, ..., n} with no LCM triangle, of size A401118(n). It takes the same Method option as A401118ILP.";

Begin["`Private`"];


(* The SCIP library is looked up relative to this file, so remember where it was loaded from *)

a401118SCIPPackageDirectory = DirectoryName[$InputFileName];


(* ::Subsection:: *)
(*SCIP through ForeignFunctionLoad*)


(* ::Text:: *)
(*Both packages solve the same kind of problem: choose as many of vars as possible, at most two from each clique. src/c/a401118_scip/a401118_scip.c solves it with SCIP. Its CMake build puts a401118_scip.dll (.so, .dylib) in src/c/a401118_scip/lib, together with SCIP's own DLLs on Windows; the environment variable A401118_SCIP_LIB can name another directory. Windows resolves a DLL's dependencies on PATH rather than next to it, so LibraryLoad loads SoPlex and SCIP from that directory first. The library is looked for once per session; a failed lookup is remembered too.*)


(* ::Text:: *)
(*The model is passed as flat arrays: weights (all 1), and the cliques in compressed form, start offsets plus 0-based variable indices. SCIP is about 5 times faster than LinearOptimization on the m = 198 problem of A401118Incremental (0.75 s against 3.7 s).*)


a401118SCIPDirectory[] := With[{env = Environment["A401118_SCIP_LIB"]},
  If[StringQ[env], env, FileNameJoin[{a401118SCIPPackageDirectory, "..", "c", "a401118_scip", "lib"}]]]

a401118SCIPFunction[] := a401118SCIPFunction[] = Module[{dir = a401118SCIPDirectory[], lib, f},
  lib = FileNameJoin[{dir, "a401118_scip" <> Switch[$OperatingSystem, "Windows", ".dll", "MacOSX", ".dylib", _, ".so"]}];
  If[! FileExistsQ[lib], Return[$Failed, Module]];
  If[$OperatingSystem === "Windows",
   Scan[Quiet[LibraryLoad[#]] &, Join[FileNames["libsoplex*.dll", dir], FileNames["libscip*.dll", dir]]]];
  f = Quiet[ForeignFunctionLoad[lib, "a401118_scip_max",
     {"CInt", "RawPointer"::["CDouble"], "CInt", "RawPointer"::["CInt"], "RawPointer"::["CInt"], "CDouble", "RawPointer"::["CInt"]} -> "CInt"]];
  If[Head[f] === ForeignFunction, f, $Failed]]

(* a401118SCIPSolve[f, head][vars, cliques] gives the elements of vars kept in an optimal solution. On a SCIP error code it gives head::scipfail and solves that problem with lcmTriangleMax from A401118Incremental.wl, which has the same contract. *)

a401118SCIPSolve[f_, head_][vars_List, cliques_List] := Module[{pos, idx, start, out, val},
  pos = AssociationThread[vars -> Range[0, Length[vars] - 1]];
  idx = Flatten[Lookup[pos, #] & /@ cliques];
  start = Prepend[Accumulate[Length /@ cliques], 0];
  out = RawMemoryAllocate["CInt", Length[vars]];
  val = f[Length[vars], RawMemoryExport[ConstantArray[1., Length[vars]], "CDouble"], Length[cliques],
    RawMemoryExport[start, "CInt"], RawMemoryExport[If[idx === {}, {0}, idx], "CInt"], 0., out];
  If[val < 0,
   Message[head::scipfail, val]; lcmTriangleMax[vars, cliques],
   Pick[vars, RawMemoryImport[out, {"List", Length[vars]}], 1]]]

(* A401118ILP.wl's a401118ILPSet with SCIP in place of its LinearOptimization call *)

a401118SCIPILPSet[n_Integer, solve_] := Module[{cliques = a401118Cliques[n], vars},
  If[cliques === {}, Return[Range[n], Module]];
  vars = Union @@ cliques;
  Union[Complement[Range[n], vars], solve[vars, cliques]]]


(* ::Subsection:: *)
(*Choosing the solver*)


(* a401118SCIPMethod[head, method] gives a SCIP solve function, None to use the package's own LinearOptimization code, or $Failed after a message from head *)

a401118SCIPMethod[_, "LinearOptimization"] := None

a401118SCIPMethod[head_, method : Automatic | "SCIP"] := With[{f = a401118SCIPFunction[]},
  Which[
   f =!= $Failed, a401118SCIPSolve[f, head],
   method === Automatic, None,
   True, Message[head::noscip, a401118SCIPDirectory[]]; $Failed]]

a401118SCIPMethod[head_, method_] := (Message[head::method, method]; $Failed)


(* ::Subsection:: *)
(*The Method option*)


(* ::Text:: *)
(*The definitions with OptionsPattern[] take the calls with options. The one-argument forms are more specific, so a plain call would still reach the packages' own definitions; those are redefined here with the same left-hand sides, which replaces them, to use Method -> Automatic. Loading a package again puts its own one-argument definitions back.*)


Options[A401118ILP] = Options[A401118Incremental] = Options[A401118List] = Options[LCMTriangleFreeSubset] = {Method -> Automatic};

A401118ILP[n_Integer?Positive, opts : OptionsPattern[]] :=
  With[{s = a401118SCIPMethod[A401118ILP, OptionValue[Method]]},
   Which[s === $Failed, $Failed, s === None, Length[a401118ILPSet[n]], True, Length[a401118SCIPILPSet[n, s]]]]

A401118List[nmax_Integer?Positive, opts : OptionsPattern[]] :=
  With[{s = a401118SCIPMethod[A401118List, OptionValue[Method]]},
   If[s === $Failed, $Failed, First[a401118Run[nmax, Replace[s, None -> lcmTriangleMax]]]]]

A401118Incremental[n_Integer?Positive, opts : OptionsPattern[]] :=
  With[{s = a401118SCIPMethod[A401118Incremental, OptionValue[Method]]},
   If[s === $Failed, $Failed, Last[First[a401118Run[n, Replace[s, None -> lcmTriangleMax]]]]]]

LCMTriangleFreeSubset[n_Integer?Positive, opts : OptionsPattern[]] :=
  With[{s = a401118SCIPMethod[LCMTriangleFreeSubset, OptionValue[Method]]},
   If[s === $Failed, $Failed, Last[a401118Run[n, Replace[s, None -> lcmTriangleMax]]]]]

A401118ILP[n_Integer?Positive] := A401118ILP[n, Method -> Automatic]
A401118List[nmax_Integer?Positive] := A401118List[nmax, Method -> Automatic]
A401118Incremental[n_Integer?Positive] := A401118Incremental[n, Method -> Automatic]
LCMTriangleFreeSubset[n_Integer?Positive] := LCMTriangleFreeSubset[n, Method -> Automatic]


(* ::Subsection:: *)
(*Messages*)


Scan[
  Function[f,
    MessageName[f, "posint"] = "`1` is not a positive integer.";
    MessageName[f, "method"] = "Method -> `1` is not Automatic, \"SCIP\" or \"LinearOptimization\".";
    MessageName[f, "noscip"] = "Method -> \"SCIP\" needs the library built from src/c/a401118_scip; none was found in `1`.";
    MessageName[f, "scipfail"] = "SCIP returned error code `1`; solving this problem with LinearOptimization instead.";
    f[n_, OptionsPattern[]] /; ! (IntegerQ[n] && n > 0) := (Message[f::posint, n]; $Failed)],
  {A401118ILP, A401118Incremental, A401118List, LCMTriangleFreeSubset}]


End[];

EndPackage[];
