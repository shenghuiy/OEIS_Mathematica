(* ::Package:: *)

BeginPackage["OEIS`"];


A399539[n_Integer?Positive]:=isokSeg[n,2^16]


Begin["`Private`"];


(* ::Subsection:: *)
(*Segmented Euler Sieve *)


(* ::ItemNumbered:: *)
(*The three functions being sieved*)


(* ::Text:: *)
(*The predicate is \[Psi](k) \[Minus] \[CurlyPhi](k) = d(k)\:2074, and all three are multiplicative \[LongDash] f(ab) = f(a)f(b) whenever gcd(a,b)=1 \[LongDash] with closed forms on prime powers:*)


(* ::Input:: *)
(*Grid[Map[Style[#,18]&,{*)
(*{"\[Phi](p\:1d43)","\[Psi](p\:1d43)","d(p\:1d43)"},*)
(*{"\!\(\*SuperscriptBox[\(p\), \(a - 1\)]\)(p-1)","\!\(\*SuperscriptBox[\(p\), \(a - 1\)]\)(p+1)","a+1"}*)
(*},{2}],Dividers->All]*)


(* ::Text:: *)
(*You build f(m) from f of already-computed smaller numbers, which is why all three arrays are filled in one pass rather than calling FactorInteger N times.*)


(* ::Text:: *)
(*FunctionCompile only accepts a restricted set of functions. So the body hand-rolls trial division and builds all three quantities in a single sweep.*)


(* ::ItemNumbered:: *)
(*Factorizing sieve*)


(* ::Text:: *)
(*rem starts as the number itself and gets divided down as each prime is stripped. Its final value is the unfactored remainder.*)
(*st = Max[p p, p Quotient[lo + p - 1, p]] \[LongDash] start at the first multiple of p in the block, but never below p\.b2. This means p only ever touches m when p <= Sqrt[m].*)
(*Therefore, at the end, rem > 1 is guaranteed to be a single prime \[LongDash] a number <= hi cannot have two prime factors both exceeding Sqrt[hi]. *)
(*That's the If[r > 1, ...] cleanup, which picks up the large prime for free instead of sieving up to N. (Example: 6 is skipped by p=3 since 9 > 6, and 3 survives in rem to be handled there.)*)
(*Inside the inner loop, p | m holds by construction, so the first Quotient is unconditional and only further divisions need the q - r p != 0 test \[LongDash] saving a Mod on roughly 3N hits.*)


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


(* ::Subsubsection:: *)
(*Benchmark*)


(* ::Text:: *)
(*It takes about 5 sec to find all elements below 10^8 on Macbook pro M1Max + 32 GB*)


(* ::Program:: *)
(*In[]:= A399539[10^8]//AbsoluteTiming*)
(*Out[]= {4.73983,{2071,3007,4087,14780,17468,18428,19388,39288,114160,193340,263252,628608,755325,976284,2823876,3133344,3182328,3392260,3549105,3556196,4488544,5065092,5277051,7176924,8791600,9928704,10794375,12330540,20254976,21778944,35991872,38026716,38637144,39080960,40434636,43918956,45348384,50917248,53308125,54561364,68134912,73605120,82462800,88654800,92143980}}*)
