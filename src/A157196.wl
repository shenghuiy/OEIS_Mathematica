(* ::Package:: *)

BeginPackage["OEIS`"];


A157196::usage="A157196[n] gives the n-th term of A157196.";


Begin["`Private`"];


A157196[n_Integer?Positive]:=ToExpression@StringTake[strA157196[levelA157196[n]],{n}]


(* ::Text:: *)
(*Each string is the previous one followed by a block derived from its reverse, so every string is a prefix of the next. The length at least doubles after the first step, so a level with enough digits is found by a short loop.*)


strA157196[0]="11";
strA157196[n_]:=strA157196[n]=StringJoin[strA157196[n-1],With[{s=StringReverse[strA157196[n-1]]},If[StringStartsQ[s,"11"],"2"<>StringTake[s,2-StringLength[s]],"11"<>StringTake[s,1-StringLength[s]]]]]


levelA157196[n_]:=Module[{k=0},While[StringLength[strA157196[k]]<n,k++];k]


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Test*)


(* ::Program:: *)
(*In[]:= Array[A157196,40]*)
