(* ::Package:: *)

BeginPackage["OEIS`"];

TopSpinSolve::usage = "TopSpinSolve[state] returns a list of R, L and F move strings that solves a permutation of Range[20] in fixed positions. The solution is not necessarily shortest.";
TopSpinApply::usage = "TopSpinApply[state, moves] executes R, L and F move strings from left to right. R rotates right, L rotates left, and F reverses positions 1 through 4.";

Begin["`Private`"];

(* ::Subsection:: *)
(* States and moves *)

topSpinGroup = PermutationGroup[{
  Cycles[{Range[20]}], Cycles[{{1, 4}, {2, 3}}]
}];

topSpinStateQ[state_] := ListQ[state] && Sort[state] === Range[20];
topSpinMovesQ[moves_] := ListQ[moves] && AllTrue[moves, StringQ[#] && MemberQ[{"R", "L", "F"}, #] &];

topSpinStep[state_, "R"] := RotateRight[state];
topSpinStep[state_, "L"] := RotateLeft[state];
topSpinStep[state_, "F"] := Join[Reverse[Take[state, 4]], Drop[state, 4]];

TopSpinApply::state = "The state must be a list containing each exact integer from 1 through 20 once.";
TopSpinApply::moves = "The moves must be a list containing only the strings R, L and F.";
TopSpinSolve::state = TopSpinApply::state;
TopSpinSolve::word = "Could not obtain a verified solution word from GroupElementToWord.";

TopSpinApply[state_, moves_] := Module[{},
  If[!topSpinStateQ[state], Message[TopSpinApply::state]; Return[$Failed]];
  If[!topSpinMovesQ[moves], Message[TopSpinApply::moves]; Return[$Failed]];
  Fold[topSpinStep, state, moves]
];

(* ::Subsection:: *)
(* Generator word recovery *)

TopSpinSolve[state_] := Module[{word, moves},
  If[!topSpinStateQ[state], Message[TopSpinSolve::state]; Return[$Failed]];
  If[state === Range[20], Return[{}]];
  word = Check[GroupElementToWord[topSpinGroup, FindPermutation[state, Range[20]]], $Failed];
  If[!ListQ[word] || !AllTrue[word, MemberQ[{1, -1, 2, -2}, #] &],
    Message[TopSpinSolve::word]; Return[$Failed]
  ];
  moves = word /. {1 -> "R", -1 -> "L", 2 -> "F", -2 -> "F"};
  If[Fold[topSpinStep, state, moves] =!= Range[20],
    Message[TopSpinSolve::word]; Return[$Failed]
  ];
  moves
];

End[];
EndPackage[];
