"""Tests for src/python/a400000.py; run with: python -m unittest discover -s test/python"""

import hashlib
import os
import sys
import unittest
from fractions import Fraction

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "src", "python"))

import a400000

ALGORITHMS = (a400000.block_max, a400000.hull)

# The first 120 terms of the b-file (Eric Fox, n = 1..10000)
FIRST_120 = [
    0, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 3, 1, 2, 1, 10, 1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
    1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 11, 1, 2, 2, 3, 2, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
    1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 11, 1, 2, 2, 3, 2, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 10,
    1, 2, 2, 3, 1, 3, 1, 4, 1, 2, 4, 1, 2, 2, 1, 19, 1, 2, 2, 3, 2, 3, 2, 4]

# SHA-256 of the 10000 b-file terms joined by commas, so the test needs no network access
B_FILE_SHA256 = "209e674aa2db4afb22f71444b45e23f4376a89649b341dfdedeba6eeecf041b6"


def by_definition(n):
    """The first n terms straight from the definition, with exact line tests and no slopes or pruning."""
    a = []
    for m in range(1, n + 1):
        def seen(h):
            return sum(all(a[k - 1] <= a[i - 1] + Fraction((h - a[i - 1]) * (k - i), m - i) for k in range(i + 1, m))
                       for i in range(1, m))
        h = 0
        while seen(h) != h:
            h += 1
        a.append(h)
    return a


def records(a):
    best, out = -1, []
    for i, x in enumerate(a, 1):
        if x > best:
            best = x
            out.append((x, i))
    return out


class A400000Tests(unittest.TestCase):
    def test_first_terms(self):
        for f in ALGORITHMS:
            self.assertEqual(f(120), FIRST_120, f.__name__)

    def test_b_file(self):
        for f in ALGORITHMS:
            digest = hashlib.sha256(",".join(map(str, f(10000))).encode()).hexdigest()
            self.assertEqual(digest, B_FILE_SHA256, f.__name__)

    def test_definition(self):
        expected = by_definition(150)
        for f in ALGORITHMS:
            self.assertEqual(f(150), expected, f.__name__)

    def test_algorithms_agree(self):
        self.assertEqual(a400000.block_max(30000), a400000.hull(30000))

    def test_spikes_16k(self):
        a = a400000.block_max(112)
        self.assertEqual([a[16 * k - 1] for k in range(1, 8)], [10, 10, 11, 10, 11, 10, 19])

    def test_records_A399949_A399950(self):
        expected = list(zip([0, 1, 2, 3, 10, 11, 19, 20, 21, 111, 148, 165, 355],
                            [1, 2, 4, 8, 16, 48, 112, 282, 622, 1246, 2721, 3984, 61898]))
        self.assertEqual(records(a400000.block_max(62000)), expected)

    def test_prefix(self):
        for f in ALGORITHMS:
            self.assertEqual(f(2000)[:777], f(777), f.__name__)

    def test_small_counts(self):
        for f in ALGORITHMS:
            self.assertEqual(f(0), [], f.__name__)
            self.assertEqual(f(1), [0], f.__name__)

    def test_bad_arguments(self):
        for f in ALGORITHMS:
            for bad in (-1, 2.5, "10", True):
                with self.assertRaises(ValueError):
                    f(bad)


if __name__ == "__main__":
    unittest.main()
