(* Game tree for 10 cards (k = 4), Figure 2 of Eriksson and Jonsson, "Level sizes of the Bulgarian solitaire game tree".
   Each node is a partition and its children are its preimages, in a Tree whose children are an Association
   j -> subtree, so the keys label the edges. The loop from the staircase to itself (T in the paper) is left out.
   Run from the repository root: wolframscript -file docs/img/BulgarianSolitaireTree10.wl *)

Get["src/wolfram/BulgarianSolitaire.wl"];

root = {4, 3, 2, 1};

(* a preimage p of q comes from playing a part of q equal to Length[p]; j is that part's first position in q *)
build[q_] := Tree[Row[q], KeySort@Association[
   FirstPosition[q, Length[#]][[1]] -> build[#] & /@ DeleteCases[OEIS`BulgarianSolitairePreimages[q], root]]];

t = build[root];

(* light and dark versions, for the <picture> in docs/BulgarianSolitaire.md; {background, text, edge, node fill, node border} *)
themes = <|"light" -> {White, Black, GrayLevel[0.45], RGBColor[0.87, 0.93, 1], GrayLevel[0.6]},
   "dark" -> {RGBColor["#0d1117"], GrayLevel[0.9], GrayLevel[0.5], RGBColor[0.15, 0.2, 0.3], GrayLevel[0.4]}|>;

KeyValueMap[
  Export["docs/img/BulgarianSolitaireTree10-" <> #1 <> ".png",
    Show[Tree[t, ImageSize -> 1400, Background -> #2[[1]],
      TreeElementLabelStyle -> All -> Directive[#2[[2]], Large], ParentEdgeLabelStyle -> All -> Directive[#2[[2]], Large],
      ParentEdgeStyle -> #2[[3]], TreeElementStyle -> All -> Directive[#2[[4]], EdgeForm[#2[[5]]]]]],
    ImageResolution -> 100] &,
  themes];
