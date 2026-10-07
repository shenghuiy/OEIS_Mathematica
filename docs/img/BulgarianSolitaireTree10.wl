(* Game tree for 10 cards (k = 4), Figure 2 of Eriksson and Jonsson, "Level sizes of the Bulgarian solitaire game tree".
   Each partition is a node and its children are its preimages R_j, in a Tree whose children are an Association
   j -> subtree, so the keys j (the index of the part played in the reverse move) label the edges.
   The edge 1 from the staircase back to itself (the loop, T in the paper) is left out.
   Run from the repository root: wolframscript -file docs/img/BulgarianSolitaireTree10.wl *)

root = {4, 3, 2, 1};

(* reverse move R_j: take the j-th part, which must be at least (number of parts - 1), add 1 to every other part,
   and append (part - number of parts + 1) ones *)
revMove[q_, j_] := Sort[Join[Delete[q, j] + 1, ConstantArray[1, q[[j]] - Length[q] + 1]], Greater];

(* a repeated part gives the same child as its first copy, so only the first copy is played *)
playable[q_] := Select[Range[Length[q]],
  q[[#]] >= Length[q] - 1 && FirstPosition[q, q[[#]]][[1]] == # && revMove[q, #] =!= root &];

build[q_] := Tree[Row[ToString /@ q], Association[# -> build[revMove[q, #]] & /@ playable[q]]];

t = build[root];
Print["N ", {TreeCount[t], TreeDepth[t], Table[Length[TreeLevel[t, {d}]], {d, 0, TreeDepth[t] - 1}]}];  (* {42, 13, {1, 1, 3, 5, 5, 3, 4, 4, 4, 3, 3, 3, 3}} *)

Export["docs/img/BulgarianSolitaireTree10.png",
  Show[Tree[t, ImageSize -> 1400, Background -> White,
      TreeElementLabelStyle -> All -> Directive[Black, Large], ParentEdgeLabelStyle -> All -> Directive[Black, Large],
      ParentEdgeStyle -> GrayLevel[0.45], TreeElementStyle -> Directive[RGBColor[0.87, 0.93, 1], EdgeForm[GrayLevel[0.6]]]]],
  ImageResolution -> 100];
