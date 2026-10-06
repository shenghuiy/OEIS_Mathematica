(* Tests for src/wolfram/A316667.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A316667.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


VerificationTest[
  Take[OEIS`A316667[], 12],
  {1, 10, 3, 6, 9, 4, 7, 2, 5, 8, 11, 14},
  TestID -> "first-terms"
]

(* The knight is trapped after 2016 moves, on square 2084 *)

VerificationTest[
  {Length[#], Last[#]} &[OEIS`A316667[]],
  {2016, 2084},
  TestID -> "length-and-last-term"
]

(* No square is visited twice *)

VerificationTest[
  DuplicateFreeQ[OEIS`A316667[]],
  True,
  TestID -> "no-repeats"
]
