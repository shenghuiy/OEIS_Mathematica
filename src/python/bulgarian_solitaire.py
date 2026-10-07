"""Bulgarian solitaire on integer partitions.

Python port of src/wolfram/BulgarianSolitaire.wl; see docs/BulgarianSolitaire.md.
A partition is a tuple of positive integers in non-increasing order.
"""

from collections import Counter
from functools import lru_cache, wraps
from math import comb, gcd, isqrt


def is_partition(p):
    return (isinstance(p, tuple) and len(p) > 0
            and all(isinstance(x, int) and not isinstance(x, bool) and x > 0 for x in p)
            and all(a >= b for a, b in zip(p, p[1:])))


def _is_int(x):
    return isinstance(x, int) and not isinstance(x, bool)


def _check(valid, message):
    """Decorator: raise ValueError(message.format(arg)) unless valid(first argument)."""
    def decorate(f):
        @wraps(f)
        def wrapper(x, *args, **kwargs):
            if not valid(x):
                raise ValueError(message.format(x))
            return f(x, *args, **kwargs)
        return wrapper
    return decorate


# The same wording as the messages of the Wolfram package (::partition, ::necklace, ::posint, ::nonnegint).
_partition_arg = _check(is_partition, "{!r} is not a partition: expected a nonempty tuple of positive integers "
                                      "in non-increasing order.")
_necklace_arg = _check(lambda w: isinstance(w, (list, tuple)) and len(w) > 0 and all(_is_int(b) and b in (0, 1) for b in w),
                       "{!r} is not a necklace: expected a nonempty list of 0s and 1s.")
_posint_arg = _check(lambda n: _is_int(n) and n > 0, "{!r} is not a positive integer.")
_nonnegint_arg = _check(lambda d: _is_int(d) and d >= 0, "{!r} is not a nonnegative integer.")


def partitions(n, largest=None):
    """All partitions of n, in reverse lexicographic order."""
    if largest is None:
        largest = n
    if n == 0:
        yield ()
        return
    for first in range(min(n, largest), 0, -1):
        for rest in partitions(n - first, first):
            yield (first,) + rest


@lru_cache(maxsize=None)
def partition_number(n):
    """p(n), with p(n) = 0 for negative n."""
    if n < 0:
        return 0
    table = [1] + [0] * n
    for part in range(1, n + 1):
        for i in range(part, n + 1):
            table[i] += table[i - part]
    return table[n]


# The move

@_partition_arg
def step(p):
    """One move: take a card from every pile and make a new pile."""
    return tuple(sorted([x - 1 for x in p if x > 1] + [len(p)], reverse=True))


# Orbits and cycles

def _orbit_data(p):
    """The orbit up to the first repeat, and the number of moves before the cycle."""
    seen = {}
    orbit = []
    cur = p
    while cur not in seen:
        seen[cur] = len(orbit)
        orbit.append(cur)
        cur = _step(cur)
    return orbit, seen[cur]


@_partition_arg
def orbit(p):
    return _orbit_data(p)[0]


@_partition_arg
def distance(p):
    return _orbit_data(p)[1]


@_partition_arg
def cycle(p):
    orb, tail = _orbit_data(p)
    return orb[tail:]


# Periodic partitions (Toom, Brandt)

def triangular_root(n):
    """The m with m(m+1)/2 <= n < (m+1)(m+2)/2."""
    return (isqrt(8 * n + 1) - 1) // 2


@_partition_arg
def is_periodic(p):
    """Toom's criterion: k cells on diagonal k for k <= m, r on m + 1, none beyond."""
    n = sum(p)
    m = triangular_root(n)
    want = {k: k for k in range(1, m + 1)}
    if n - m * (m + 1) // 2 > 0:
        want[m + 1] = n - m * (m + 1) // 2
    return Counter(i + j + 1 for i, row in enumerate(p) for j in range(row)) == want


def _canonical_cycle(p):
    c = orbit(p)
    k = c.index(min(c))
    return tuple(c[k:] + c[:k])


@_posint_arg
def cycles(n):
    """Every cycle of partitions of n, each rotated to start at its smallest partition."""
    from itertools import combinations
    m = triangular_root(n)
    r = n - m * (m + 1) // 2
    found = set()
    for s in combinations(range(m + 1), r):
        rows = [m - i + (1 if i in s else 0) for i in range(m + 1)]
        found.add(_canonical_cycle(tuple(x for x in rows if x > 0)))
    return sorted(found)


def _euler_phi(n):
    return sum(1 for k in range(1, n + 1) if gcd(n, k) == 1)


@_posint_arg
def cycle_count(n):
    """Number of cycles: necklaces of m + 1 beads with r marked, by Burnside."""
    m = triangular_root(n)
    length = m + 1
    r = n - m * (m + 1) // 2
    g = gcd(length, r)
    total = sum(_euler_phi(d) * comb(length // d, r // d)
                for d in range(1, g + 1) if g % d == 0)
    return total // length


# Garden of Eden partitions (Hopkins, Sellers)

@_partition_arg
def is_garden_of_eden(p):
    return p[0] - len(p) <= -2


@_posint_arg
def garden_of_eden_count(n):
    """ge(n) = p(n-3) - p(n-9) + p(n-18) - ..."""
    total, j = 0, 1
    while 3 * j * (j + 1) // 2 <= n:
        total += (-1) ** (j + 1) * partition_number(n - 3 * j * (j + 1) // 2)
        j += 1
    return total


@_posint_arg
def garden_of_eden_partitions(n):
    return [p for p in partitions(n) if is_garden_of_eden(p)]


@_partition_arg
def preimages(p):
    """Partitions that step sends to p, sorted."""
    t = len(p)
    out = []
    for v in sorted(set(p)):
        if v >= t - 1:
            rest = list(p)
            rest.remove(v)
            out.append(tuple(sorted([x + 1 for x in rest] + [1] * (v - t + 1), reverse=True)))
    return sorted(out)


# Game graph and level sizes

@_posint_arg
def graph(n):
    """The game graph as a dict from each partition of n to its image."""
    return {p: _step(p) for p in partitions(n)}


@_posint_arg
def levels(n):
    """Partitions of n grouped by distance to the cycles."""
    succ = graph(n)
    pre = {}
    for p, q in succ.items():
        pre.setdefault(q, []).append(p)
    level = [p for p in pre if is_periodic(p)]
    out = []
    while level:
        out.append(level)
        level = [q for p in level for q in pre.get(p, []) if not is_periodic(q)]
    return out


@_posint_arg
def level_sizes(n):
    return [len(lev) for lev in levels(n)]


@_posint_arg
def leaf_sizes(n):
    return [sum(1 for p in lev if is_garden_of_eden(p)) for lev in levels(n)]


def _fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a


@_nonnegint_arg
def quasi_level_size(d):
    """Level size of the quasi-infinite game: 1 for d = 0, else F(2d)."""
    return 1 if d == 0 else _fib(2 * d)


@_nonnegint_arg
def quasi_leaf_size(d):
    """Leaf count (F(2d-2) - F(d-1))/2 for d >= 1, 0 for d = 0."""
    return 0 if d == 0 else (_fib(2 * d - 2) - _fib(d - 1)) // 2


# Row-to-column game

@_partition_arg
def row_moves(p):
    """Partitions reached by changing any one row of the Ferrers diagram into a column."""
    out = set()
    for j in range(1, p[0] + 1):
        conj_j = sum(1 for x in p if x >= j)
        new = [x - 1 if x >= j else x for x in p] + [conj_j]
        out.add(tuple(sorted((x for x in new if x > 0), reverse=True)))
    return sorted(out)


# Level sizes of one cycle (Pham)

@_necklace_arg
def periodic_partition(necklace):
    """The cycle partition for a necklace of m + 1 beads (1 = filled cell on diagonal m + 1)."""
    m1 = len(necklace)
    rows = [m1 - 1 - i + bead for i, bead in enumerate(necklace)]
    return tuple(x for x in rows if x > 0)


@_partition_arg
def basin_levels(p):
    """The partitions at each distance from the cycle p ends in, counting only that cycle's basin."""
    cyc = cycle(p)
    seen = set(cyc)
    level, out = list(cyc), []
    while level:
        out.append(level)
        nxt = []
        for q in level:
            for r in _preimages(q):
                if r not in seen:
                    seen.add(r)
                    nxt.append(r)
        level = nxt
    return out


@_partition_arg
def basin_level_sizes(p):
    """Number of partitions at each distance from the cycle p ends in."""
    return [len(lev) for lev in basin_levels(p)]


@_posint_arg
def max_distance(n):
    """The largest number of moves any partition of n needs to reach a cycle (the game tree's height)."""
    return len(levels(n)) - 1


@_posint_arg
def cycle_lengths(n):
    """The sorted lengths of the cycles of partitions of n."""
    return sorted(len(c) for c in cycles(n))


@_partition_arg
def component(p):
    """The cycle p ends in and every partition that flows into it, in order of distance from the cycle."""
    return [q for lev in basin_levels(p) for q in lev]


@_partition_arg
def reversed_tree(p):
    """The component of p with the edges reversed, as a dict from each partition to its preimages that are
    not on the cycle. Each partition off the cycle has exactly one parent."""
    cyc = set(cycle(p))
    return {q: [r for r in _preimages(q) if r not in cyc] for q in component(p)}


# The unchecked versions, for the loops that call them on partitions already known to be valid.
_step = step.__wrapped__
_preimages = preimages.__wrapped__
