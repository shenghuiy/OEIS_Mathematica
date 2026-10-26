"""A400000, the city-building sequence.

a(n) is the least height h such that a building of height h at position n sees exactly h of
the earlier buildings; building k is seen when every building between has its top on or below
the line joining the two tops. See docs/A400000.md.

Two exact algorithms, which give the same terms:

- block_max(n): the method of src/wolfram/A400000.wl. The backward scan skips whole aligned
  blocks of 2^j buildings whose tallest building is below the line of sight.
- hull(n): keeps the upper convex hull of the rooftops on a monotone stack. The farthest building
  seen is the hull vertex with the steepest line of sight, so the scan stops there.

Both keep the integer slope test of the OEIS programs: scanning back from the new building at
x = m with height h, building k (dx = m - k, dy = a(k) - h) is seen when dx0 * dy >= dx * dy0,
where dy0 / dx0 is the steepest line of sight found so far.
"""


def _check_count(n):
    if not isinstance(n, int) or isinstance(n, bool) or n < 0:
        raise ValueError("{!r} is not a nonnegative integer.".format(n))


def block_max(n):
    """The first n terms, by the backward scan with block maxima."""
    _check_count(n)
    a = []
    lv = [None]  # lv[j][b] = max(a[b * 2^j : (b + 1) * 2^j]), complete blocks only; level 0 is a
    for m in range(n):
        h = 0
        while True:
            c = dx0 = dy0 = 0
            k = m - 1
            while k >= 0 and c <= h:
                # the largest aligned block ending at k, then smaller ones, until one can be skipped
                j = min(((k + 1) & -(k + 1)).bit_length() - 1, len(lv) - 1)
                while j > 0:
                    size = 1 << j
                    # the lowest point of the bound h + (dy0 / dx0) dx over the block
                    req = dy0 * (m - k) if dy0 >= 0 else dy0 * (m - k + size - 1)
                    if (lv[j][((k + 1) >> j) - 1] - h) * dx0 < req:
                        break
                    j -= 1
                if j > 0:
                    k -= 1 << j
                    continue
                dx, dy = m - k, a[k] - h
                if dx0 * dy >= dx * dy0:
                    c += 1
                    dx0, dy0 = dx, dy
                k -= 1
            if c == h:
                break
            h += 1
        a.append(h)
        # fill every block that building m completes
        j = 1
        while (m + 1) % (1 << j) == 0:
            if len(lv) == j:
                lv.append([])
            b = ((m + 1) >> j) - 1
            below = a if j == 1 else lv[j - 1]
            lv[j].append(max(below[2 * b], below[2 * b + 1]))
            j += 1
    return a


def hull(n):
    """The first n terms, by the backward scan stopped at the tangent point of the upper hull."""
    _check_count(n)
    a = []
    hx, hy = [], []  # upper hull of the tops, left to right; collinear points kept
    for m in range(n):
        h = 0
        while True:
            c = 0
            if hx:
                # the steepest line of sight (a(k) - h) / (m - k) is unimodal along the hull;
                # binary search for its leftmost maximum, the farthest building that can be seen
                lo, hi = 0, len(hx) - 1
                while lo < hi:
                    mid = (lo + hi) // 2
                    if (hy[mid] - h) * (m - hx[mid + 1]) < (hy[mid + 1] - h) * (m - hx[mid]):
                        lo = mid + 1
                    else:
                        hi = mid
                stop = hx[lo]
                dx0 = dy0 = 0
                k = m - 1
                while k >= stop and c <= h:
                    dx, dy = m - k, a[k] - h
                    if dx0 * dy >= dx * dy0:
                        c += 1
                        dx0, dy0 = dx, dy
                    k -= 1
            if c == h:
                break
            h += 1
        a.append(h)
        while len(hx) >= 2 and (hx[-1] - hx[-2]) * (h - hy[-2]) - (hy[-1] - hy[-2]) * (m - hx[-2]) > 0:
            hx.pop()
            hy.pop()
        hx.append(m)
        hy.append(h)
    return a


if __name__ == "__main__":
    import sys
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    print(*block_max(count), sep=", ")
