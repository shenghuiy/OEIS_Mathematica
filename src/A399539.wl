(* ::Package:: *)

BeginPackage["OEIS`"];


A399539[n_Integer?Positive]:=isokSeg[n,10^4]


Begin["`Private`"];


(* ::Subsection:: *)
(*Segmented Euler Sieve *)


(* ::Text:: *)
(*Use FunctionCompile *)


isokSeg=FunctionCompile@Function[{Typed[nmax,"MachineInteger"],Typed[bsize,"MachineInteger"]},Module[{rt,comp,primes,np=0,rem,psi,phi,d,hi,len,p,st,idx,e,pe,q,r,res},
rt=Floor[Sqrt[N[nmax]]]+1;
comp=Typed[CreateDataStructure["FixedArray",rt+1],"FixedArray"::["MachineInteger"]];
primes=Typed[CreateDataStructure["FixedArray",rt+1],"FixedArray"::["MachineInteger"]];
Do[If[comp["Part",i]==0,np=np+1;primes["SetPart",np,i];
Do[comp["SetPart",j,1],{j,i i,rt,i}]],{i,2,rt}];
rem=Typed[CreateDataStructure["FixedArray",bsize],"FixedArray"::["MachineInteger"]];
psi=Typed[CreateDataStructure["FixedArray",bsize],"FixedArray"::["MachineInteger"]];
phi=Typed[CreateDataStructure["FixedArray",bsize],"FixedArray"::["MachineInteger"]];
d=Typed[CreateDataStructure["FixedArray",bsize],"FixedArray"::["MachineInteger"]];
res=Typed[CreateDataStructure["DynamicArray"],"DynamicArray"::["MachineInteger"]];
Do[
hi=Min[lo+bsize-1,nmax];
len=hi-lo+1;
Do[
rem["SetPart",i,lo+i-1];
psi["SetPart",i,1];
phi["SetPart",i,1];
d["SetPart",i,1],{i,1,len}];
Do[p=primes["Part",k];
If[p*p<=hi,st=Max[p*p,p*Quotient[lo+p-1,p]];
Do[idx=m-lo+1;
q=Quotient[rem["Part",idx],p];e=1;pe=1;
While[True,r=Quotient[q,p];If[q-r p!=0,Break[]];q=r;e=e+1;pe=pe p];
rem["SetPart",idx,q];
psi["SetPart",idx,psi["Part",idx] (p+1) pe];
phi["SetPart",idx,phi["Part",idx] (p-1) pe];
d["SetPart",idx,d["Part",idx] (e+1)],{m,st,hi,p}]],{k,1,np}];
Do[r=rem["Part",i];
If[r>1,psi["SetPart",i,psi["Part",i] (r+1)];
phi["SetPart",i,phi["Part",i] (r-1)];
d["SetPart",i,2 d["Part",i]]];
r=d["Part",i];
If[psi["Part",i]-phi["Part",i]==r ^4,res["Append",lo+i-1]],{i,1,len}],{lo,1,nmax,bsize}];
res["Elements"]]];


End[];


EndPackage[];
