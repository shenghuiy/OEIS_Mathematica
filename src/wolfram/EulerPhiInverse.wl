(* ::Package:: *)

(* Compiled search for the solutions of EulerPhi[x] == n. *)

BeginPackage["OEIS`"];

EulerPhiInverse::usage = "EulerPhiInverse[n] returns the sorted list of all x with EulerPhi[x] == n.";

Begin["`Private`"];


(* ::Subsection:: *)
(*The compiled search*)


(* ::Text:: *)
(*If p^e divides x then p - 1 divides phi(x) = n, so only the primes p with p - 1 | n are candidates. The search is a depth-first walk over them from the largest down: with remaining target x and product y so far, a prime p with p - 1 | x divides x by p - 1, then for e = 1, 2, ... multiplies y by p and recurses on the quotient by p^(e-1) using only smaller primes. When the target reaches 1, y is a solution.*)


(* ::Text:: *)
(*A recursive call is made only when the quotient q can still be completed: q = 1 is a solution on the spot (and so is 2 y when the prime 2 is still unused, since phi(2) = 1), while an odd q > 1, or a q with no smaller primes left, is a dead end and is skipped without a call. This removes about 85% of the nodes visited.*)


(* ::Text:: *)
(*Solutions are appended to a growable DynamicArray, so a single pass finds them all. The kernel uses Integer64, which is safe when n < 2^58, because then every solution x < 7.5 n < 2^63 and every intermediate product is at most 2 n. The result starts with a 0 so it is never empty (compiled code cannot return an empty array); callers drop it.*)


makeSearch[] := With[{t = "Integer64"},
  FunctionCompile[Function[{Typed[n, t]},
    Module[{res, dfs, divs, primes},
      res = Typed[CreateDataStructure["DynamicArray"], "DynamicArray"::[t]];
      res["Append", TypeHint[0, t]];
      dfs = Function[{Typed[x, t], Typed[y, t], Typed[ub, "MachineInteger"], Typed[pl, "ListVector"::[t]]},
        Module[{t1, t2, c, i, q, p},
          i = ub;
          While[i >= 1,
            p = pl[[i]];
            If[Mod[x, p - 1] == 0,
              t1 = Quotient[x, p - 1];
              t2 = y; c = TypeHint[1, t];
              While[Mod[t1, c] == 0,
                t2 *= p;
                q = Quotient[t1, c];
                If[q == 1,
                  res["Append", t2];
                  If[i > 1, res["Append", 2 t2]],
                  If[i > 1 && EvenQ[q], dfs[q, t2, i - 1, pl]]];
                c *= p]];
            i--];
          0]];
      If[EvenQ[n],
        divs = Typed[KernelFunction[Divisors], {t} -> "ListVector"::[t]][n];
        primes = Select[divs, Typed[KernelFunction[PrimeQ], {t} -> "Boolean"][# + 1] &];
        dfs[n, TypeHint[1, t], Length[primes], Map[# + 1 &, primes]]];
      res["Elements"]]]]]


(* ::Text:: *)
(*The kernel is compiled the first time it is needed, so loading the package is instant.*)


searchKernel[] := searchKernel[] = makeSearch[]


(* ::Subsection:: *)
(*EulerPhiInverse*)


(* ::Text:: *)
(*EulerPhi[1] = EulerPhi[2] = 1, but phi(x) is even for x > 2, so every other odd n has no solution and is answered without compiling anything. For n >= 2^58 the Integer64 kernel could overflow, so the Function Repository's EulerPhiInverse is used instead.*)


EulerPhiInverse[1] := {1, 2}

EulerPhiInverse[n_Integer?Positive] := Which[
  OddQ[n], {},
  n < 2^58, Sort[Rest[searchKernel[][n]]],
  True, Sort[ResourceFunction["EulerPhiInverse"][n]]]


End[];

EndPackage[];
