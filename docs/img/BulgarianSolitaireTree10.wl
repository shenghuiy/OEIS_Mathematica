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

Export["docs/img/BulgarianSolitaireTree10.png",
  Show[Tree[t, ImageSize -> 1400, Background -> White,
    TreeElementLabelStyle -> All -> Directive[Black, Large], ParentEdgeLabelStyle -> All -> Directive[Black, Large],
    ParentEdgeStyle -> GrayLevel[0.45], TreeElementStyle -> Directive[RGBColor[0.87, 0.93, 1], EdgeForm[GrayLevel[0.6]]]]],
  ImageResolution -> 100];
