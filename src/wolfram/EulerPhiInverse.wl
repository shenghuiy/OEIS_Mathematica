(* ::Package:: *)

(* Compiled search for the solutions of EulerPhi[x] == n. *)

BeginPackage["OEIS`"];

EulerPhiInverse::usage = "EulerPhiInverse[n] returns the sorted list of all x with EulerPhi[x] == n.";

Begin["`Private`"];


cf2=FunctionCompile[Function[{Typed[n,"Integer128"],Typed[bound,"MachineInteger"]},Module[{ele,res,temp=TypeHint[0,"Integer128"],dfs,tot,fa,init1,init2},
fa=CreateDataStructure["FixedArray",TypeHint[0,"Integer128"],bound];
tot=ToRawPointer[TypeHint[0,"Integer64"]];
dfs=Function[{
Typed[x,"Integer128"],Typed[y,"Integer128"],
Typed[ub,"MachineInteger"],
Typed[pl,"ListVector"::["Integer128"]],
Typed[increPt,"RawPointer"::["Integer64"]]},
Module[{t1,t2,c,i},If[ub==-1,i=Length[pl],i=ub];
While[i>=1&&FromRawPointer[tot]<bound,
If[Mod[x,pl[[i]]-1]==0,
t1=Quotient[x,(pl[[ i ]]-1)];
t2=y;c=TypeHint[1,"Integer128"];
While[FromRawPointer[tot]<bound&&Mod[t1,c]==0,
t2*=pl[[ i ]];dfs[Quotient[t1,c],t2,i-1,pl,increPt];c*=pl[[ i ]]]];i--];If[FromRawPointer[tot]<bound&&x==1,
ToRawPointer[tot,FromRawPointer[tot]+1];
fa["SetPart",FromRawPointer[tot],y];,0;
]]
];
If[OddQ[n],{fa,0},
init1=Typed[KernelFunction[Divisors],{"Integer128"}->"ListVector"::["Integer128"]][n];
init2=Select[init1,Typed[KernelFunction[PrimeQ],{"Integer128"}->"Boolean"][#+1]&];
dfs[n,TypeHint[1,"Integer128"],-1,Map[#+1&,init2],tot];
{fa,FromRawPointer[tot]}]]]]


(* ::Text:: *)
(*Extract the values in the data structure*)


cfExtract=FunctionCompile[Function[{Typed[arg1,"FixedArray"::["Integer128"]],Typed[arg2,"MachineInteger"]},
If[arg2==0,{TypeHint[0,"Integer128"]},Take[arg1["Elements"],{1,arg2}]]
]]


(* ::Subsection:: *)
(*EulerPhiInverse*)


(* ::Text:: *)
(*cf2 stops after bound solutions, so a returned count equal to bound may mean the list was cut off. The bound is doubled until the count falls strictly below it, then cfExtract reads the stored solutions. cfExtract returns {0} for a zero count, so that case is mapped to {}. EulerPhi[1] = EulerPhi[2] = 1, but cf2 returns nothing for odd n, so n = 1 is handled directly.*)


EulerPhiInverse[1] := {1, 2}

EulerPhiInverse[n_Integer?Positive] := Module[{bound = 1024, fa, count},
  While[
    {fa, count} = cf2[n, bound];
    count >= bound,
    bound *= 2];
  If[count == 0, {}, Sort[cfExtract[fa, count]]]
]


End[];

EndPackage[];
