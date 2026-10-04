(* Tests for src/wolfram/A157196.wl *)

VerificationTest[
  Get[FileNameJoin[{DirectoryName[$TestFileName], "..", "..", "src", "wolfram", "A157196.wl"}]];
  True,
  True,
  TestID -> "load-package"
]


VerificationTest[
  Array[OEIS`A157196, 20],
  {1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1},
  TestID -> "first-terms"
]

(* Terms are 1s and 2s *)

VerificationTest[
  SubsetQ[{1, 2}, Array[OEIS`A157196, 300]],
  True,
  TestID -> "only-ones-and-twos"
]

(* Each string is a prefix of the next, so terms do not depend on the level reached *)

VerificationTest[
  AllTrue[Range[0, 7],
    StringStartsQ[OEIS`Private`strA157196[# + 1], OEIS`Private`strA157196[#]] &],
  True,
  TestID -> "strings-are-prefixes"
]

VerificationTest[
  Array[OEIS`A157196, 100],
  ToExpression /@ Characters[StringTake[OEIS`Private`strA157196[OEIS`Private`levelA157196[100]], 100]],
  TestID -> "terms-read-from-string"
]

(* levelA157196[n] is the first level whose string has at least n digits *)

VerificationTest[
  AllTrue[{1, 2, 3, 10, 50, 500},
    With[{k = OEIS`Private`levelA157196[#]},
      StringLength[OEIS`Private`strA157196[k]] >= # &&
      (k == 0 || StringLength[OEIS`Private`strA157196[k - 1]] < #)] &],
  True,
  TestID -> "level-is-minimal"
]

(* Non-positive or non-integer arguments are not evaluated *)

VerificationTest[OEIS`A157196[0], OEIS`A157196[0], TestID -> "zero-unevaluated"]


(* Examples from docs/A157196.md *)

VerificationTest[
  Array[OEIS`A157196, 10],
  {1, 1, 2, 1, 1, 1, 1, 2, 1, 1},
  TestID -> "example-first-10"
]

VerificationTest[
  Array[OEIS`A157196, 23],
  {1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 1, 1, 2},
  TestID -> "example-first-23"
]

(* Joining the first 193 terms gives a[7], the string in the original code comment *)

VerificationTest[
  StringJoin[ToString /@ Array[OEIS`A157196, 193]],
  OEIS`Private`strA157196[7],
  TestID -> "example-193-terms-are-a7"
]

VerificationTest[StringLength[OEIS`Private`strA157196[7]], 193, TestID -> "example-a7-length"]

(* Density of 1s over the first 2^14 terms is about 2/3 (0.66669) *)

VerificationTest[
  Round[N[Count[Array[OEIS`A157196, 2^14], 1]/2^14], 10^-5],
  0.66669,
  SameTest -> (Abs[#1 - #2] < 10^-5 &),
  TestID -> "example-density-of-ones"
]
