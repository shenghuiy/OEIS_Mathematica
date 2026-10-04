(* ::Package:: *)

(* Translation of a PARI/GP function. PARI's eta(x^k + A) on a power series is
   the product Prod_{m>=1} (1 - x^(k m)), without the x^(1/24) factor. *)

BeginPackage["OEIS`"];


etaSeries::usage="etaSeries[k, nn] gives Prod_{m>=1}(1 - x^(k m)) as a polynomial in x, truncated after x^nn.";
A003785::usage="A003785[n] gives the n-th term of A003785 (0 for n < 3).";


Begin["`Private`"];


etaSeries[k_Integer?Positive,nn_Integer?NonNegative]:=Normal@Series[QPochhammer[x^k,x^k,nn+1],{x,0,nn}]


A003785[n_Integer]:=If[n<3,0,
  Module[{m=n-3,e1,e2,e4,A1},
    e1=etaSeries[1,m];e2=etaSeries[2,m];e4=etaSeries[4,m];
    A1=Series[(e2^3/e1/e4^2)^4,{x,0,m}];
    SeriesCoefficient[(A1+4x/A1)*e2^7*e4^18/e1^2,{x,0,m}]
  ]
]


End[];


EndPackage[];
