(* ::Package:: *)

BeginPackage["OEIS`"];

TopSpinSolve::usage = "TopSpinSolve[state] returns a list of R, L and F move strings that solves a permutation of Range[20] in fixed positions. The solution is not necessarily shortest. With \"CompressRotations\" -> True, each run of rotations is one step, written Rk or Lk for k positions (R or L for one).";
TopSpinApply::usage = "TopSpinApply[state, moves] executes R, L and F move strings from left to right. R rotates right, L rotates left, and F reverses positions 1 through 4. Rk and Lk rotate k positions.";

Begin["`Private`"];

(* ::Subsection:: *)
(* States and moves *)

topSpinStateQ[state_] := ListQ[state] && Sort[state] === Range[20];
topSpinMovesQ[moves_] := ListQ[moves] && AllTrue[moves, StringQ[#] && StringMatchQ[#, RegularExpression["F|[RL]([1-9][0-9]*)?"]] &];

topSpinStep[state_, "R"] := RotateRight[state];
topSpinStep[state_, "L"] := RotateLeft[state];
topSpinStep[state_, "F"] := Join[Reverse[Take[state, 4]], Drop[state, 4]];
topSpinStep[state_, move_String] := With[{k = Mod[FromDigits[StringDrop[move, 1]], 20]},
  If[StringStartsQ[move, "R"], RotateRight[state, k], RotateLeft[state, k]]
];

TopSpinApply::state = "The state must be a list containing each exact integer from 1 through 20 once.";
TopSpinApply::moves = "The moves must be a list containing only the strings R, L and F, and Rk and Lk for a positive integer k.";
TopSpinSolve::state = TopSpinApply::state;

TopSpinApply[state_, moves_] := Module[{},
  If[!topSpinStateQ[state], Message[TopSpinApply::state]; Return[$Failed]];
  If[!topSpinMovesQ[moves], Message[TopSpinApply::moves]; Return[$Failed]];
  Fold[topSpinStep, state, moves]
];

(* ::Subsection:: *)
(* Normal form *)

(* ::Text:: *)
(* R generates a cyclic group of order 20 and F one of order 2, so every word is R^r0 F R^r1 F ... F R^rk. topSpinAmounts gives the rotation amounts r0, ..., rk mod 20. A word is reduced when no inner amount is 0 (an F F pair with nothing between cancels). topSpinConcat appends a word to a reduced one, cancelling F pairs as long as the amount at the junction is 0, and topSpinMoves writes r as R^r for r <= 10 and as L^(20 - r) otherwise. topSpinSteps writes each nonzero r as one step instead: Rr (R for 1) for r <= 10, and Lk (L for 1) with k = 20 - r otherwise. *)

topSpinAmounts[word_String] := Mod[StringCount[#, "R"] - StringCount[#, "L"], 20] & /@ StringSplit[word, "F", All];

topSpinConcat[a_, w_] := Module[{s = a, i = 2},
  s[[-1]] = Mod[s[[-1]] + w[[1]], 20];
  While[s[[-1]] == 0 && Length[s] > 1 && i <= Length[w],
    s = Most[s]; s[[-1]] = Mod[s[[-1]] + w[[i]], 20]; i++
  ];
  Join[s, w[[i ;;]]]
];

topSpinReduce[word_String] := With[{a = topSpinAmounts[word]},
  Fold[topSpinConcat, {First[a]}, {0, #} & /@ Rest[a]]
];

topSpinMoves[a_] := Flatten[Riffle[If[# <= 10, ConstantArray["R", #], ConstantArray["L", 20 - #]] & /@ a, "F"]];

topSpinRun[r_] := Which[r == 0, "", r == 1, "R", r <= 10, "R" <> IntegerString[r], r == 19, "L", True, "L" <> IntegerString[20 - r]];
topSpinSteps[a_] := DeleteCases[Riffle[topSpinRun /@ a, "F"], ""];

(* ::Subsection:: *)
(* Word table *)

(* ::Text:: *)
(* The solver sifts through the stabilizer chain of base positions 20, 19, ..., 2. Row i of topSpinTable is for base position b = 21 - i. Its entry k (k < b) is a reduced word whose moves leave the tokens in positions b + 1 through 20 in place and bring the token in position k to position b. topSpinBuildTable regenerates the table. *)

topSpinTable = {
  {"L", "LL", "RFL", "FL", "LFL", "LLFL", "LLLFL", "LLLLFL", "LLLLLFL", "LLLLLLFL", "RRRRRRRRR",
    "RRRRRRRR", "RRRRRRR", "RRRRRR", "RRRRR", "RRRR", "RRR", "RR", "R"},
  {"RFLLLL", "FRFLLFRFL", "RFLLFRFL", "RFLFLL", "RRFLLFLFLL", "RFLFLFLFLL", "RFLLLFLFLL",
    "RFLLFLLFLFLL", "RFLLFLFLLFLFLL", "RFLLLFLLLFLFLL", "RRRFRFRRFRRRFL", "RRRFRRFRRRFL",
    "RRRRFRRRFL", "RRRFRFRRFL", "RRRFRRFL", "RRRRFL", "RRFRFL", "RFLFRRFL"},
  {"RFRFLLFRFLL", "FRRFLFLLL", "RRFLFLLL", "LFRRRFLFLLL", "RRFLFLFLFLLL", "RFRFLLLFLFLLL",
    "RRFLLFLLFLFLLL", "RFRFLLFLFLLFLFLLL", "RRFLFLFLLFLLFLFLLL", "RRRRFRRFRRFRRFLL",
    "RRRRFRRFRRRFLFL", "RRRRFRRFRFRFLL", "RRRRFRFRRFLFL", "RRRRFRRFLL", "RRRRRFLFL", "RRRFRFLL",
    "RRFLFRRFLFL"},
  {"RFRFRFLLLLLL", "RRRFLFLLLL", "FRRRFLFLLLL", "FRFRFRFLLLLLL", "LFRRRRFLFLLLL",
    "LLFRRFRRRFLFLLLL", "LLLFRFRFRRRRFLFLLLL", "LLLLFRRRFRRRRFLFLLLL", "RRRRFRFRFRFRFRFRFRFLLL",
    "RRRRFRFRFRFRRRFLFLFL", "RRRRFRFRFRFRFRFLLL", "RRRRFRFRRRFLFLFL", "RRRRFRFRFRFLLL",
    "RRRRRRFLFLFL", "RRRRFRFLLL", "RRFRFLFRRFLLL"},
  {"RRRFRFLFRFLLLLL", "FRFRFRFRFLLLLLLL", "RFRFRFRFLLLLLLL", "RFLFRRRRFLFLLLLL",
    "LFRFRFRFRFRFLLLLLLL", "LLFRRRFRFRFRFLLLLLLL", "LLLLLLFLLLFLLLFLLLLLLLL",
    "LLLLLLLFLFLFLLLFLLLLLLLL", "LLLLLLLLFLLFLLFLLLLLLLL", "LLLLLLLLLFLLLFLLLLLLLL",
    "RRRRRRRRRRFLFLFLLLLLLLL", "RRRRRRFLLFRRRRFLLFLL", "RRRRRRRFLFLFLFL", "RRRRRFRFLLLLFRFL",
    "RRRRRFLFRFLFLLL"},
  {"RFRFRFRFRFLLLLLLLL", "RFRFRRRFLFLLLLFLFRFLFL", "RRFLFRRRRFLFLLLLLL",
    "RRFLFLFRRFRRRFLFLLLLFLL", "RRFLFLFLFRFRFRRRRFLFLLLLLL", "LLLLLFLLLFLLLFLLLLLLLLL",
    "LLLLLLFLFLFLLLFLLLLLLLLL", "LLLLLLLFLLFLLFLLLLLLLLL", "LLLLLLLLFLLLFLLLLLLLLL",
    "LLLLLLLLLFLFLFLLLLLLLLL", "LLLLLLLLLFLLFLLLLLLLLL", "RRRRRRRRFLFLFLFLFL",
    "RRRRRRFRFLLLLFRFLL", "RRFRRRFRRRFLLLFLLLFLL"},
  {"RRFRFRFRRFRRFLLFLLFLFLFLL", "RRRFLFRRRRFLFLLLLLLL", "RFRFRFRFRFRFLLLLLLLLL",
    "RRRFLFLFLFRRRRRRFLFLFLFLLLLLLL", "RFLFLFRRRRFLFRRRRFLFLLLLLLFL",
    "RRRFLFLFLFLFRFLLFRRFRRFRRRRFLFLLLLLFLL", "LLLLLLFLLFLLFRRRRRRRRRR", "LLLLLLLFLLLFRRRRRRRRRR",
    "LLLLLLLLFLFLFRRRRRRRRRR", "LLLLLLLLFLLFRRRRRRRRRR", "RRRRRRRRRRFRRRRRRRRRR",
    "RRRRRRRFRFLLLLFRFLLL", "RRRFRRRFRRRFLLLFLLLFLLL"},
  {"RFRFRFRFRFRFRFRRRRRRRRRR", "RFRFRFRFRRRFLFLLLLFLFRFLFLLL", "RFRFRFRFRFRFRFRRFLFRRRRRRRRR",
    "LLLFLLLFLLLFRRRRRRRRR", "LLLLFLFLFLLLFRRRRRRRRR", "LLLLLFLLFLLFRRRRRRRRR",
    "LLLLLLFLLLFRRRRRRRRR", "LLLLLLLFLFLFRRRRRRRRR", "LLLLLLLFLLFRRRRRRRRR", "LLLLLLLLLFRRRRRRRRR",
    "LLLLLLLLFLFRRRRRRRRR", "LLLLLLLLLFRFLFRRRRRRRRR"},
  {"RRRFRFLFRFRRRFRFLFRFLLLLLLLLL", "RRRFLFRRRRFLFRRRRFLFRRFRFLFRRRRRRRR", "LLFLLLFLLLFRRRRRRRR",
    "LLLFLFLFLLLFRRRRRRRR", "LLLLFLLFLLFRRRRRRRR", "LLLLLFLLLFRRRRRRRR", "LLLLLLFLFLFRRRRRRRR",
    "LLLLLLFLLFRRRRRRRR", "LLLLLLLLFRRRRRRRR", "LLLLLLLFLFRRRRRRRR", "LLLLLLLLFRFLFRRRRRRRR"},
  {"FLLFLLFLLLFRRRRRRR", "LFLLLFLLLFRRRRRRR", "LLFLFLFLLLFRRRRRRR", "LLLFLLFLLFRRRRRRR",
    "LLLLFLLLFRRRRRRR", "LLLLLFLFLFRRRRRRR", "LLLLLFLLFRRRRRRR", "LLLLLLLFRRRRRRR",
    "LLLLLLFLFRRRRRRR", "LLLLLLLFRFLFRRRRRRR"},
  {"FLLLFLLLFRRRRRR", "LFLFLFLLLFRRRRRR", "LLFLLFLLFRRRRRR", "LLLFLLLFRRRRRR", "LLLLFLFLFRRRRRR",
    "LLLLFLLFRRRRRR", "LLLLLLFRRRRRR", "LLLLLFLFRRRRRR", "LLLLLLFRFLFRRRRRR"},
  {"FLFLFLLLFRRRRR", "LFLLFLLFRRRRR", "LLFLLLFRRRRR", "LLLFLFLFRRRRR", "LLLFLLFRRRRR",
    "LLLLLFRRRRR", "LLLLFLFRRRRR", "LLLLLFRFLFRRRRR"},
  {"FLLFLLFRRRR", "LFLLLFRRRR", "LLFLFLFRRRR", "LLFLLFRRRR", "LLLLFRRRR", "LLLFLFRRRR",
    "LLLLFRFLFRRRR"},
  {"FLLLFRRR", "LFLFLFRRR", "LFLLFRRR", "LLLFRRR", "LLFLFRRR", "LLLFRFLFRRR"},
  {"FLFLFRR", "FLLFRR", "LLFRR", "LFLFRR", "LLFRFLFRR"},
  {"FLFRFLFR", "LFR", "FLFR", "LFRFLFR"},
  {"F", "LFLFRFLFRFRFLLFRFR", "RFRFLLFRFRFLFRFLFL"},
  {"FLFRRFLFLFRFLFRFRFL", "FRRFLFLFRFLFRFRFLFL"},
  {"FLFRFLLFLFLFLFLFLFLFLFLFLFLFLFLFLFLFLFLFR"}
};

topSpinWords = Map[topSpinAmounts, topSpinTable, {2}];
topSpinInverse = Map[InversePermutation[Fold[topSpinStep, Range[20], Characters[#]]] &, topSpinTable, {2}];

(* ::Subsection:: *)
(* Solving *)

(* ::Text:: *)
(* Applying a word w to a state s gives s[[p]] for an index list p, and the solved state needs p = Ordering[s]. At base position b, x[[b]] = k says which entry of row 21 - b to use. Its word goes on the solution, and x becomes its inverse index list composed with x, which fixes b. After 19 rows x is the identity. "CompressRotations" only changes how the reduced word is written out. *)

Options[TopSpinSolve] = {"CompressRotations" -> False};

TopSpinSolve[state_, opts : OptionsPattern[]] := Module[{x, words = {}, b, k,
    unknown = FilterRules[{opts}, Except[Options[TopSpinSolve]]], compress},
  If[!topSpinStateQ[state], Message[TopSpinSolve::state]; Return[$Failed]];
  If[unknown =!= {}, Message[TopSpinSolve::optx, First[First[unknown]], HoldForm[TopSpinSolve[state, opts]]]; Return[$Failed]];
  compress = OptionValue["CompressRotations"];
  If[!BooleanQ[compress], Message[TopSpinSolve::opttf, "CompressRotations", compress]; Return[$Failed]];
  x = Ordering[state];
  Do[
    b = 21 - i; k = x[[b]];
    If[k != b, AppendTo[words, topSpinWords[[i, k]]]; x = topSpinInverse[[i, k]][[x]]],
    {i, 19}
  ];
  If[compress, topSpinSteps, topSpinMoves][Fold[topSpinConcat, {0}, words]]
];

(* ::Subsection:: *)
(* Rebuilding the table *)

(* ::Text:: *)
(* Minkwitz's algorithm (1998) fills the table with short words. It runs through every reduced word in R, L and F in order of length and sifts each one: at each base position it either finds the slot for its target empty (or holding a longer word) and stores itself there, or strips the stored word off its front and moves to the next base position. Every period words it also sifts the products of pairs of words in the same row. Words longer than cap are dropped, and cap grows by a quarter after a pass that leaves the table incomplete. *)

(* ::Text:: *)
(* Entry k of row i is slot 20 (i - 1) + k. Moves are 1 = R, 2 = L, 3 = F, with index lists gens. A word's index list p satisfies p[[base[[j]]]] = base[[j]] for the rows j it has passed. The result is {filled slots, final cap, 380 word lengths (-1 for empty), the 380 x wmax word array}. The compile takes about a minute, and runs once, on the first call of topSpinBuildTable. *)

topSpinMinkwitz := topSpinMinkwitz = FunctionCompile[Function[{
    Typed[gens, "PackedArray"::["MachineInteger", 2]],
    Typed[base, "PackedArray"::["MachineInteger", 1]],
    Typed[maxIter, "MachineInteger"], Typed[period, "MachineInteger"],
    Typed[initCap, "MachineInteger"], Typed[wmax, "MachineInteger"]},
  Module[{n = 20, nl = 19, need = 190, invMove = {2, 1, 3},
     tabLen, tabWord, tabP, tabPinv, p, t, oldP, oldT, tmp, idP,
     tlen = 0, oldLen = 0, ulen = 0, c = 0, e = 0, x = 0, i = 0,
     cap = initCap, count = 0, filled = 0, len = 1, first = 1, bits = 0,
     phase = 0, j = 1, a = 1, b = 0, eA = 0, eB = 0, m = 0, prev = 0, bit = 0,
     done = False, ok = False},
   idP = Range[n];
   tabLen = ConstantArray[-1, 380];
   tabWord = ConstantArray[0, {380, wmax}];
   tabP = ConstantArray[0, {380, n}];
   tabPinv = ConstantArray[0, {380, n}];
   Do[e = (i - 1)*n + base[[i]]; tabLen[[e]] = 0; tabP[[e]] = idP; tabPinv[[e]] = idP, {i, nl}];
   t = ConstantArray[0, wmax]; p = idP;
   While[! done,
    ok = False;
    If[phase == 0,
     (* next reduced word: a first move, then for each later move one bit choosing between the two moves that do not cancel the one before *)
     If[count >= maxIter, done = True,
      count++;
      If[len <= cap,
       t[[1]] = first; prev = first; p = gens[[first]];
       Do[bit = BitAnd[BitShiftRight[bits, k - 2], 1];
        m = If[prev == 3, 1 + bit, If[bit == 0, prev, 3]];
        t[[k]] = m; prev = m; p = p[[gens[[m]]]], {k, 2, len}];
       tlen = len; ok = True];
      bits++;
      If[bits >= BitShiftLeft[1, len - 1], bits = 0; first++;
       If[first > 3, first = 1; len++]];
      If[Mod[count, period] == 0, phase = 1; j = 1; a = 1; b = 0]],
     (* improvement pass: the product of entries a and b of row j *)
     b++;
     If[b > n, b = 1; a++; If[a > n, a = 1; j++]];
     If[j > nl,
      phase = 0;
      If[filled < need, cap = Min[wmax, cap + Max[1, Quotient[cap, 4]]]],
      eA = (j - 1)*n + a; eB = (j - 1)*n + b;
      If[tabLen[[eA]] > 0 && tabLen[[eB]] > 0 && tabLen[[eA]] + tabLen[[eB]] <= cap,
       tlen = tabLen[[eA]] + tabLen[[eB]];
       t[[1 ;; tabLen[[eA]]]] = tabWord[[eA, 1 ;; tabLen[[eA]]]];
       t[[tabLen[[eA]] + 1 ;; tlen]] = tabWord[[eB, 1 ;; tabLen[[eB]]]];
       p = tabP[[eA]][[tabP[[eB]]]];
       ok = True]]];
    If[ok,
     i = 1;
     While[i <= nl && tlen >= 0,
      x = p[[base[[i]]]];
      If[x != base[[i]],
       e = (i - 1)*n + x;
       If[tabLen[[e]] < 0,
        tabWord[[e]] = t; tabLen[[e]] = tlen; tabP[[e]] = p;
        Do[tabPinv[[e, p[[q]]]] = q, {q, n}];
        filled++; tlen = -1,
        If[tlen < tabLen[[e]],
         oldLen = tabLen[[e]]; oldT = tabWord[[e]]; oldP = tabP[[e]];
         tabWord[[e]] = t; tabLen[[e]] = tlen; tabP[[e]] = p;
         Do[tabPinv[[e, p[[q]]]] = q, {q, n}];
         t = oldT; tlen = oldLen; p = oldP];
        (* strip the stored word: its inverse goes in front, cancelling the prefix the two words share *)
        ulen = tabLen[[e]]; c = 0;
        While[c < ulen && c < tlen && tabWord[[e, c + 1]] == t[[c + 1]], c++];
        If[ulen + tlen - 2 c > cap, tlen = -1,
         tmp = ConstantArray[0, wmax];
         If[ulen > c, tmp[[1 ;; ulen - c]] = invMove[[Reverse[tabWord[[e, c + 1 ;; ulen]]]]]];
         If[tlen > c, tmp[[ulen - c + 1 ;; ulen + tlen - 2 c]] = t[[c + 1 ;; tlen]]];
         t = tmp; tlen = ulen + tlen - 2 c;
         p = tabPinv[[e]][[p]]]]];
      i++]]];
   Join[{filled, cap}, tabLen, Flatten[tabWord]]]]];

topSpinBuildTable[iterations_Integer?Positive] := Module[{raw, lens, words},
  raw = topSpinMinkwitz[topSpinStep[Range[20], #] & /@ {"R", "L", "F"}, Range[20, 2, -1],
    iterations, Max[5000, Quotient[iterations, 50]], 30, 200];
  If[raw[[1]] != 190, Return[$Failed]];
  lens = raw[[3 ;; 382]];
  words = MapThread[Take, {Partition[raw[[383 ;;]], 200], Clip[lens, {0, Infinity}]}];
  Table[
    StringJoin[topSpinMoves[topSpinReduce[StringJoin[{"R", "L", "F"}[[words[[20 (i - 1) + k]]]]]]]],
    {i, 19}, {k, 20 - i}
  ]
];

End[];
EndPackage[];
