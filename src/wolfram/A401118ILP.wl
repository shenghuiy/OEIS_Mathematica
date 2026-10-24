(* ::Package:: *)

(* A401118 by integer linear programming: the size of the largest subset of {1..n} with no 3-element subset whose pairwise LCMs are all equal (Erdos problem #536). The OEIS entry's b-file (n <= 656) was computed this way. A401118.wl has the exhaustive search, which stops being practical past n = 30. *)

BeginPackage["OEIS`"];

A401118ILP::usage = "A401118ILP[n] gives the size of the largest subset of {1..n} having no 3-element subset {x, y, z} with lcm(x, y) = lcm(y, z) = lcm(z, x), by solving an integer linear program.";

Begin["`Private`"];


(* ::Subsection:: *)
(*LCM cliques*)


(* ::Text:: *)
(*In an LCM triangle {x, y, z} all three pairs have the same LCM L. So group the pairs of {1..n} by their LCM, and for each L draw the graph whose edges are the pairs with that LCM: the LCM triangles are exactly the triangles of these graphs. Any three numbers in a clique of one graph form an LCM triangle, so a valid subset takes at most two numbers from each clique. a401118Cliques lists the maximal cliques of 3 or more vertices, each sorted; every LCM triangle lies in one of them.*)


a401118Cliques[n_Integer?NonNegative] :=
  Module[{groups},
    groups = Select[GroupBy[Subsets[Range[n], {2}], Apply[LCM] -> Identity], Length[#] >= 3 &];
    Join @@ Values@Map[
      Sort /@ Select[FindClique[Graph[UndirectedEdge @@@ #], Infinity, All], Length[#] >= 3 &] &,
      groups]]


(* ::Subsection:: *)
(*Integer linear program*)


(* ::Text:: *)
(*One 0/1 variable per number that is in some clique: maximize their sum subject to Total[clique] <= 2 for every clique. The numbers in no clique are always taken. One constraint per maximal clique instead of one per triangle gives a tighter LP relaxation: at n = 200 it is 732 constraints instead of 868, and the solve takes 4.3 s instead of 7.5 s. LinearOptimization solves it with CBC (Method -> Automatic picks it for integer variables). a401118ILPSet returns an optimal subset; A401118ILP its size.*)


a401118ILPSet[n_Integer?NonNegative] :=
  Module[{cliques = a401118Cliques[n], vars, x, sol},
    If[cliques === {}, Return[Range[n]]];
    vars = Union @@ cliques;
    sol = LinearOptimization[-Total[x /@ vars],
      Join[Total[x /@ #] <= 2 & /@ cliques, Thread[0 <= x /@ vars <= 1]],
      (x /@ vars) \[Element] Integers];
    Union[Complement[Range[n], vars], Select[vars, Round[x[#] /. sol] == 1 &]]]


A401118ILP[n_Integer?Positive] := Length[a401118ILPSet[n]]


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Benchmark*)


(* ::Text:: *)
(*Windows 11, Mathematica 15.0.1, Wolfram MCP evaluator (local kernel). All 73 DATA terms take 1.3 s. The values match the OEIS b-file.*)


(* ::Program:: *)
(*n     A401118ILP   time*)
(*100   76           0.08 s*)
(*200   146          4.3 s*)
(*300   218          12.8 s*)
(*400   290          45 s*)
