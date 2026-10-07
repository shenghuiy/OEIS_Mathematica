"""Check Pham's conjecture on the level-size series H_P(x) of Bulgarian solitaire.

For a primitive necklace P (1 = black B, 0 = white W) let H_P(x) be the limit of the level-size generating
functions of the basin of P^k as k grows. Pham conjectured that H_P and H_P*, where P* is P read backwards with
the colours swapped, have the same denominator, of degree exactly |P|. This script reads the first terms of H_P
off the basin of P^k, fits the smallest rational function, and compares denominators. See
docs/BulgarianSolitaire.md.

    python src/python/pham_conjecture.py 3 5        # every primitive necklace with 3 <= |P| <= 5

Stdlib only. The cost grows about 2.5 times per extra term, so |P| = 5 takes about a minute and |P| = 6 many
minutes.
"""
import itertools
import sys
from fractions import Fraction

import bulgarian_solitaire as bs


def canonical(w):
    return min(tuple(w[i:] + w[:i]) for i in range(len(w)))


def dual(w):
    """Read backwards and swap the colours."""
    return canonical([1 - b for b in reversed(w)])


def is_primitive(w):
    n = len(w)
    return all(tuple(w[i:] + w[:i]) != tuple(w) for i in range(1, n) if n % i == 0)


def name(w):
    return "".join("B" if b else "W" for b in w)


def head(w, k, terms):
    """The first `terms` level sizes of the basin of w^k. Only the first about 2k of them equal those of H_w."""
    cyc = bs.cycle(bs.periodic_partition(list(w) * k))
    on_cycle = set(cyc)
    level, out = list(cyc), []
    for _ in range(terms):
        out.append(len(level))
        # a partition off the cycle has one image, so no seen-set is needed beyond the cycle itself
        level = [r for q in level for r in bs.preimages(q) if r not in on_cycle]
        if not level:
            break
    return out


def series(w, terms):
    """The first `terms` coefficients of H_w, from k = terms // 2 + 1 repeats, confirmed with one more repeat."""
    k = terms // 2 + 1
    a, b = head(w, k, terms), head(w, k + 1, terms)
    if a != b:
        raise ValueError("series not stable for %s with %d terms" % (name(w), terms))
    return a


def _solve(rows, rhs):
    """Solve rows x = rhs over the rationals (free variables 0); None if inconsistent."""
    n = len(rows[0])
    m = [r[:] + [v] for r, v in zip(rows, rhs)]
    pivots, r = [], 0
    for c in range(n):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None:
            continue
        m[r], m[p] = m[p], m[r]
        m[r] = [x / m[r][c] for x in m[r]]
        for i in range(len(m)):
            if i != r and m[i][c] != 0:
                f = m[i][c]
                m[i] = [x - f * y for x, y in zip(m[i], m[r])]
        pivots.append(c)
        r += 1
    if any(all(x == 0 for x in row[:-1]) and row[-1] != 0 for row in m):
        return None
    x = [Fraction(0)] * n
    for i, c in enumerate(pivots):
        x[c] = m[i][-1]
    return x


def fit(h, p):
    """The rational function with the smallest denominator degree b <= p (then numerator degree a <= 2p) that
    matches h with at least two spare equations. Returns (a, b, [1, q1, ..., qb]) or None."""
    h = [Fraction(v) for v in h]
    n = len(h)
    for b in range(p + 1):
        for a in range(2 * p + 1):
            if n - 1 - a < b + 2:
                continue
            if b == 0:
                if all(h[k] == 0 for k in range(a + 1, n)):
                    return a, 0, [Fraction(1)]
                continue
            x = _solve([[h[k - i] for i in range(1, b + 1)] for k in range(a + 1, n)],
                       [-h[k] for k in range(a + 1, n)])
            if x is not None:
                return a, b, [Fraction(1)] + x
    return None


def check(p):
    """Compare each primitive necklace of length p with its dual; yields one result per pair {P, P*}."""
    terms = 3 * p + 3
    for w in sorted({canonical(list(t)) for t in itertools.product((0, 1), repeat=p)}):
        d = dual(list(w))
        if not is_primitive(list(w)) or (d < w and is_primitive(list(d))):
            continue
        h1, h2 = series(w, terms), series(d, terms)
        f1, f2 = fit(h1, p), fit(h2, p)
        yield w, d, h1, h2, f1, f2


def main(lo, hi):
    for p in range(lo, hi + 1):
        for w, d, h1, h2, f1, f2 in check(p):
            print("%s vs %s (|P| = %d)" % (name(w), name(d), p))
            print("   H_P  = %s ..." % h1[:10])
            print("   H_P* = %s ..." % h2[:10])
            if f1 is None or f2 is None:
                print("   no fit within the degree bounds")
                continue
            q1 = [str(c) for c in f1[2]]
            q2 = [str(c) for c in f2[2]]
            print("   denominator of P : degree %d, 1 + %s" % (f1[1], " + ".join("%s x^%d" % (c, i + 1) for i, c in enumerate(q1[1:]))))
            print("   denominator of P*: degree %d" % f2[1])
            print("   " + ("same denominator" if q1 == q2 else "DIFFERENT denominators")
                  + (", same series" if h1 == h2 else ""))
            sys.stdout.flush()


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
