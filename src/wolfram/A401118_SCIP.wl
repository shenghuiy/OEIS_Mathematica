(* ::Package:: *)

(* SCIP for A401118Incremental.wl: a Method option on A401118Incremental, A401118List and LCMTriangleFreeSubset that solves the package's 0-1 programs with SCIP (src/c/a401118_scip, through ForeignFunctionLoad) or with LinearOptimization. Loads A401118Incremental.wl first when it is not loaded yet. *)

If[DownValues[OEIS`Private`a401118Run] === {}, Get[FileNameJoin[{DirectoryName[$InputFileName], "A401118Incremental.wl"}]]];

BeginPackage["OEIS`"];

A401118Incremental::usage = "A401118Incremental[n] gives the size of the largest subset of {1, ..., n} that contains no LCM triangle: no three elements i, j, k with lcm(i, j) = lcm(j, k) = lcm(k, i). The option Method -> Automatic, \"SCIP\" or \"LinearOptimization\" picks the integer solver; Automatic uses SCIP when its library is found.";
A401118List::usage = "A401118List[nmax] gives {a(1), ..., a(nmax)} for A401118. It takes the same Method option as A401118.";
LCMTriangleFreeSubset::usage = "LCMTriangleFreeSubset[n] gives a largest subset of {1, ..., n} with no LCM triangle, of size A401118Incremental[n]. It takes the same Method option as A401118.";

Begin["`Private`"];


(* The SCIP library is looked up relative to this file, so remember where it was loaded from *)

a401118SCIPPackageDirectory = DirectoryName[$InputFileName];


(* ::Subsection:: *)
(*SCIP through ForeignFunctionLoad*)


(* ::Text:: *)
(*src/c/a401118_scip/a401118_scip.c solves the same 0-1 program as lcmTriangleMax in A401118Incremental.wl, with SCIP. Its CMake build puts a401118_scip.dll (.so, .dylib) in src/c/a401118_scip/lib, together with SCIP's own DLLs on Windows; the environment variable A401118_SCIP_LIB can name another directory. Windows resolves a DLL's dependencies on PATH rather than next to it, so LibraryLoad loads SoPlex and SCIP from that directory first. The library is looked for once per session; a failed lookup is remembered too.*)


(* ::Text:: *)
(*The model is passed as flat arrays: weights (all 1), and the cliques in compressed form, start offsets plus 0-based variable indices. SCIP is about 5 times faster than LinearOptimization on the m = 198 problem (0.75 s against 3.7 s).*)


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

(* Same contract as lcmTriangleMax: the elements of vars kept in an optimal solution. A SCIP error code falls back to LinearOptimization for that problem. *)

lcmTriangleMaxSCIP[f_][vars_List, cliques_List] := Module[{pos, idx, start, out, val},
  pos = AssociationThread[vars -> Range[0, Length[vars] - 1]];
  idx = Flatten[Lookup[pos, #] & /@ cliques];
  start = Prepend[Accumulate[Length /@ cliques], 0];
  out = RawMemoryAllocate["CInt", Length[vars]];
  val = f[Length[vars], RawMemoryExport[ConstantArray[1., Length[vars]], "CDouble"], Length[cliques],
    RawMemoryExport[start, "CInt"], RawMemoryExport[If[idx === {}, {0}, idx], "CInt"], 0., out];
  If[val < 0,
   Message[A401118Incremental::scipfail, val]; lcmTriangleMax[vars, cliques],
   Pick[vars, RawMemoryImport[out, {"List", Length[vars]}], 1]]]


(* ::Subsection:: *)
(*Choosing the solver*)


(* a401118Solver[head, method] gives the function to call as solve[vars, cliques], or $Failed after a message from head *)

a401118Solver[_, "LinearOptimization"] := lcmTriangleMax

a401118Solver[head_, method : Automatic | "SCIP"] := With[{f = a401118SCIPFunction[]},
  Which[
   f =!= $Failed, lcmTriangleMaxSCIP[f],
   method === Automatic, lcmTriangleMax,
   True, Message[head::noscip, a401118SCIPDirectory[]]; $Failed]]

a401118Solver[head_, method_] := (Message[head::method, method]; $Failed)


(* Calls without options, which A401118Incremental.wl defines, now use the Automatic choice too *)

a401118DefaultSolver[head_] := a401118Solver[head, Automatic]


(* ::Subsection:: *)
(*The Method option*)


(* ::Text:: *)
(*A401118Incremental.wl defines the one-argument forms, which are more specific than these and use a401118DefaultSolver; these definitions take the calls with options.*)


Options[A401118Incremental] = Options[A401118List] = Options[LCMTriangleFreeSubset] = {Method -> Automatic};

A401118List[nmax_Integer?Positive, opts : OptionsPattern[]] :=
  With[{solve = a401118Solver[A401118List, OptionValue[Method]]},
   If[solve === $Failed, $Failed, First[a401118Run[nmax, solve]]]]

A401118Incremental[n_Integer?Positive, opts : OptionsPattern[]] :=
  With[{solve = a401118Solver[A401118Incremental, OptionValue[Method]]},
   If[solve === $Failed, $Failed, Last[First[a401118Run[n, solve]]]]]

LCMTriangleFreeSubset[n_Integer?Positive, opts : OptionsPattern[]] :=
  With[{solve = a401118Solver[LCMTriangleFreeSubset, OptionValue[Method]]},
   If[solve === $Failed, $Failed, Last[a401118Run[n, solve]]]]


(* ::Subsection:: *)
(*Messages*)


A401118Incremental::scipfail = "SCIP returned error code `1`; solving this problem with LinearOptimization instead.";

Scan[
  Function[f,
    MessageName[f, "method"] = "Method -> `1` is not Automatic, \"SCIP\" or \"LinearOptimization\".";
    MessageName[f, "noscip"] = "Method -> \"SCIP\" needs the library built from src/c/a401118_scip; none was found in `1`.";
    f[n_, OptionsPattern[]] /; ! (IntegerQ[n] && n > 0) := (Message[f::posint, n]; $Failed)],
  {A401118Incremental, A401118List, LCMTriangleFreeSubset}]


End[];

EndPackage[];
