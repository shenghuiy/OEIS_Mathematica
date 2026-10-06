(* ::Package:: *)

(* *)

BeginPackage["OEIS`"];

A316667::usage = "A316667[] returns the 2016 spiral numbers visited by the trapped knight, from 1 to its last square 2084.";

Begin["`Private`"];


(* ::Subsection:: *)
(*The trapped knight walk*)


A316667[]:=Block[{stk,latticeHt,knightMove,grid,gridIdx,invLookup,knightNext},
stk=CreateDataStructure["Stack"];
latticeHt=CreateDataStructure["HashTable"]; 
knightMove={{2,1},{1,2},{-1,2},{-2,1},{-2,-1},{-1,-2},{1,-2},{2,-1}}; 
grid=Most[Round@ResourceFunction["SquareSpiralPoints"][120]]; 
gridIdx=AssociationThread[grid->Range[Length[grid]]];
invLookup=AssociationThread[Range[Length[grid]]->grid];
knightNext[curr_]:=Module[{mvSet,pick},
If[!latticeHt["EmptyQ"],
latticeHt["KeyDrop",curr];
mvSet=Select[Threaded[curr]+knightMove,latticeHt["KeyExistsQ",#]&];
If[mvSet=!={},
pick=ResourceFunction["PositionLargestBy"][mvSet,-latticeHt["Lookup",#]&];
latticeHt["KeyDrop",pick];
mvSet[[pick]],mvSet
],0]
];
Scan[latticeHt["Insert",#]&,Normal[gridIdx]];
Nest[(stk["Push",#];knightNext[#])&,{0,0},2016]; 
gridIdx/@stk["Elements"]
]


End[];

EndPackage[];
