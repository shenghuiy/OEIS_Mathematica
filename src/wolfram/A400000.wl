(* ::Package:: *)

BeginPackage["OEIS`"];


A400000::usage="A400000[n] gives the first n terms of A400000, the city-building sequence: a(n) is the least height h such that a building of height h at position n sees exactly h of the earlier buildings.";


Begin["`Private`"];


(* ::Subsection:: *)
(*Pruned backward scan*)


(* ::Text:: *)
(*A building at position n of height h sees the earlier building at k when every building strictly between them has its top on or below the line joining the two tops. Scanning back from n-1, k is visible exactly when the slope from (n, h) to (k, a(k)) is at least the steepest slope dy0/dx0 seen so far; in integers, dx0 (a(k) - h) >= (n - k) dy0.*)


(* ::Text:: *)
(*The program on the OEIS page tries h = 0, 1, 2, ... and stops a scan once more than h buildings are visible. The winning h never stops early, so it walks back over every earlier building, and n terms take O(n^2) steps.*)


(* ::Text:: *)
(*Here the scan skips whole blocks. The line of sight needs a height of at least h + (dy0/dx0) dx at distance dx, so if the tallest building of a block is below that bound at the block's lowest point (its near end when dy0 >= 0, its far end otherwise), nothing in the block is visible. Block maxima are kept for aligned blocks of 2, 4, 8, ... buildings, and at each step the scan tries the largest aligned block that ends at k, then smaller ones, down to the building itself, where the test is exact.*)


(* ::Text:: *)
(*Positions are 0-based in the loop (building k is a["Part", k+1]). Level j >= 1 holds Quotient[nmax, 2^j] block maxima, starting at off["Part", j] + 1 in lv; block b of level j covers buildings b 2^j .. (b+1) 2^j - 1 and is filled once building (b+1) 2^j - 1 is placed.*)


a400000Pruned=FunctionCompile@Function[{Typed[nmax,"MachineInteger"]},Module[{a,lv,off,nlev,tot,m,h,c,dx0,dy0,k,j,t,size,b,bmax,req,skipped,dx,dy,i,u,v},
a=Typed[CreateDataStructure["DynamicArray"],"DynamicArray"::["MachineInteger"]];
nlev=0;While[BitShiftLeft[1,nlev+1]<=nmax,nlev=nlev+1];
off=Typed[CreateDataStructure["FixedArray",nlev+1],"FixedArray"::["MachineInteger"]];
tot=0;
Do[off["SetPart",j,tot];tot=tot+BitShiftRight[nmax,j],{j,1,nlev}];
lv=Typed[CreateDataStructure["FixedArray",Max[tot,1]],"FixedArray"::["MachineInteger"]];
Do[
h=0;
While[True,
c=0;dx0=0;dy0=0;k=m-1;
While[k>=0&&c<=h,
t=k+1;j=0;
While[BitAnd[t,1]==0&&j<nlev,t=BitShiftRight[t,1];j=j+1];
skipped=False;
While[j>0&&!skipped,
size=BitShiftLeft[1,j];
b=BitShiftRight[k+1,j]-1;
bmax=lv["Part",off["Part",j]+b+1];
req=If[dy0>=0,dy0 (m-k),dy0 (m-k+size-1)];
If[(bmax-h) dx0<req,k=k-size;skipped=True,j=j-1]];
If[!skipped,
dx=m-k;dy=a["Part",k+1]-h;
If[dx0 dy>=dx dy0,c=c+1;dx0=dx;dy0=dy];
k=k-1]];
If[c==h,Break[]];
h=h+1];
a["Append",h];
i=m+1;j=1;
While[j<=nlev&&BitAnd[i,BitShiftLeft[1,j]-1]==0,
b=BitShiftRight[i,j]-1;
If[j==1,
u=a["Part",2 b+1];v=a["Part",2 b+2],
u=lv["Part",off["Part",j-1]+2 b+1];v=lv["Part",off["Part",j-1]+2 b+2]];
lv["SetPart",off["Part",j]+b+1,Max[u,v]];
j=j+1],
{m,0,nmax-1}];
a["Elements"]]];


A400000[n_Integer?Positive]:=a400000Pruned[n]


End[];


EndPackage[];


(* ::Subsubsection:: *)
(*Benchmark*)


(* ::Text:: *)
(*See docs/A400000.md for timings.*)
