"""Tests for src/python/bulgarian_solitaire.py; run with: python -m unittest discover -s test/python"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "src", "python"))

import bulgarian_solitaire as bs


def all_partitions(lo, hi):
    return [p for n in range(lo, hi + 1) for p in bs.partitions(n)]


def norm(cycles):
    return sorted(sorted(c) for c in cycles)


class StepTests(unittest.TestCase):
    def test_examples(self):
        self.assertEqual(bs.step((6, 4, 3, 1, 1)), (5, 5, 3, 2))
        self.assertEqual(bs.step((3, 2, 1)), (3, 2, 1))
        self.assertEqual(bs.step((4, 2, 2)), (3, 3, 1, 1))
        self.assertEqual(bs.step((3, 3, 1, 1)), (4, 2, 2))
        self.assertEqual(bs.step((6,)), (5, 1))

    def test_preserves_sum_and_shape(self):
        for p in all_partitions(1, 12):
            q = bs.step(p)
            self.assertEqual(sum(q), sum(p))
            self.assertTrue(bs.is_partition(q))

    def test_partition_counts(self):
        self.assertEqual([len(list(bs.partitions(n))) for n in range(1, 11)],
                         [bs.partition_number(n) for n in range(1, 11)])
        self.assertEqual(bs.partition_number(10), 42)


class OrbitTests(unittest.TestCase):
    def test_fifteen_cards(self):
        p = (6, 4, 3, 1, 1)
        self.assertEqual(bs.orbit(p), [(6, 4, 3, 1, 1), (5, 5, 3, 2), (4, 4, 4, 2, 1), (5, 3, 3, 3, 1),
                                       (5, 4, 2, 2, 2), (5, 4, 3, 1, 1, 1), (6, 4, 3, 2), (5, 4, 3, 2, 1)])
        self.assertEqual(bs.cycle(p), [(5, 4, 3, 2, 1)])
        self.assertEqual(bs.distance(p), 7)

    def test_eight_cards(self):
        self.assertEqual(sorted(bs.cycle((4, 3, 1))), sorted([(4, 3, 1), (3, 3, 2), (3, 2, 2, 1), (4, 2, 1, 1)]))
        self.assertEqual(bs.distance((4, 3, 1)), 0)

    def test_figure_1(self):
        self.assertEqual(bs.distance((3, 3, 2, 1, 1)), 12)

    def test_igusa(self):
        for k in range(3, 9):
            gamma = (k - 1, k - 1) + tuple(range(k - 2, 0, -1)) + (1,)
            self.assertEqual(bs.distance(gamma), k * (k - 1))

    def test_orbit_closes(self):
        for p in bs.partitions(14):
            o = bs.orbit(p)
            self.assertEqual(len(o), len(set(o)))
            self.assertIn(bs.step(o[-1]), o)


class PeriodicTests(unittest.TestCase):
    def test_matches_distance(self):
        for p in all_partitions(1, 16):
            self.assertEqual(bs.is_periodic(p), bs.distance(p) == 0, p)

    def test_examples(self):
        self.assertTrue(bs.is_periodic((5, 4, 4, 2, 2, 1)))
        self.assertFalse(bs.is_periodic((5, 4, 1)))
        self.assertEqual([p for p in bs.partitions(15) if bs.is_periodic(p)], [(5, 4, 3, 2, 1)])


class CycleTests(unittest.TestCase):
    def test_eight(self):
        self.assertEqual(norm(bs.cycles(8)),
                         norm([[(4, 2, 2), (3, 3, 1, 1)], [(4, 3, 1), (3, 3, 2), (3, 2, 2, 1), (4, 2, 1, 1)]]))

    def test_small(self):
        self.assertEqual(bs.cycles(6), [((3, 2, 1),)])
        self.assertEqual(bs.cycles(1), [((1,),)])
        self.assertEqual(len(bs.cycles(17)), 3)

    def test_match_brute_force(self):
        for n in range(1, 19):
            brute = {tuple(sorted(bs.cycle(p))) for p in bs.partitions(n)}
            self.assertEqual({tuple(sorted(c)) for c in bs.cycles(n)}, brute, n)
            periodic = sorted(p for p in bs.partitions(n) if bs.is_periodic(p))
            self.assertEqual(sorted(p for c in bs.cycles(n) for p in c), periodic, n)

    def test_count(self):
        self.assertEqual([bs.cycle_count(n) for n in range(1, 13)], [1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2])
        self.assertEqual(bs.cycle_count(17), 3)
        for n in range(1, 41):
            self.assertEqual(bs.cycle_count(n), len(bs.cycles(n)), n)


class GardenOfEdenTests(unittest.TestCase):
    def test_examples(self):
        self.assertTrue(bs.is_garden_of_eden((4, 4, 3, 3, 2, 2, 2)))
        self.assertTrue(bs.is_garden_of_eden((3, 3, 2, 1, 1)))
        self.assertFalse(bs.is_garden_of_eden((3, 2, 1)))
        self.assertEqual(sorted(bs.garden_of_eden_partitions(6)), sorted([(2, 2, 1, 1), (2, 1, 1, 1, 1), (1,) * 6]))

    def test_iff_no_preimage(self):
        for p in all_partitions(1, 16):
            self.assertEqual(bs.is_garden_of_eden(p), bs.preimages(p) == [], p)

    def test_preimages(self):
        self.assertEqual(bs.preimages((6, 5)), sorted([(7, 1, 1, 1, 1), (6, 1, 1, 1, 1, 1)]))
        for n in range(1, 15):
            parts = list(bs.partitions(n))
            for p in parts:
                self.assertEqual(bs.preimages(p), sorted(q for q in parts if bs.step(q) == p), p)

    def test_count(self):
        self.assertEqual([bs.garden_of_eden_count(n) for n in range(1, 13)], [0, 0, 1, 1, 2, 3, 5, 7, 10, 14, 20, 27])
        self.assertEqual(bs.garden_of_eden_count(20), bs.partition_number(17) - bs.partition_number(11) + bs.partition_number(2))
        for n in range(1, 41):
            self.assertEqual(bs.garden_of_eden_count(n), len(bs.garden_of_eden_partitions(n)), n)


class LevelTests(unittest.TestCase):
    def test_graph(self):
        g = bs.graph(10)
        self.assertEqual(len(g), 42)
        self.assertEqual(g[(4, 3, 2, 1)], (4, 3, 2, 1))

    def test_six_and_ten(self):
        self.assertEqual(bs.level_sizes(6), [1, 1, 2, 3, 2, 1, 1])
        self.assertEqual(bs.leaf_sizes(6), [0, 0, 0, 1, 1, 0, 1])
        self.assertEqual(bs.level_sizes(10), [1, 1, 3, 5, 5, 3, 4, 4, 4, 3, 3, 3, 3])
        self.assertEqual(bs.leaf_sizes(10), [0, 0, 0, 1, 3, 1, 1, 1, 2, 1, 1, 0, 3])
        lev = bs.levels(10)
        self.assertEqual(lev[0], [(4, 3, 2, 1)])
        self.assertEqual(sorted(lev[12]), sorted([(3, 3, 2, 1, 1), (3, 2, 2, 2, 1), (3, 2, 2, 1, 1, 1)]))

    def test_sums_and_height(self):
        for n in range(1, 21):
            self.assertEqual(sum(bs.level_sizes(n)), bs.partition_number(n))
            self.assertEqual(sum(bs.leaf_sizes(n)), bs.garden_of_eden_count(n))
        for k in range(2, 8):
            self.assertEqual(len(bs.level_sizes(k * (k + 1) // 2)) - 1, k * (k - 1))

    def test_theorem_5_1(self):
        for k in range(3, 9):
            sizes = bs.level_sizes(k * (k + 1) // 2)
            h = k // 2
            self.assertEqual(sizes[:h + 1], [bs.quasi_level_size(d) for d in range(h + 1)], k)
            deficit = 1 if k % 2 else 1 + k // 2
            self.assertEqual(bs.quasi_level_size(h + 1) - sizes[h + 1], deficit, k)


class QuasiInfiniteTests(unittest.TestCase):
    def test_values(self):
        self.assertEqual([bs.quasi_level_size(d) for d in range(9)], [1, 1, 3, 8, 21, 55, 144, 377, 987])
        self.assertEqual([bs.quasi_leaf_size(d) for d in range(8)], [0, 0, 0, 1, 3, 9, 25, 68])

    def test_generating_functions(self):
        # leaf series (x^3 - x^4)/((1 - x - x^2)(1 - 3x + x^2)); denominator 1 - 4x + 3x^2 + 2x^3 - x^4
        num = {3: 1, 4: -1}
        c = []
        for n in range(21):
            v = num.get(n, 0)
            for i, a in enumerate([4, -3, -2, 1], start=1):
                if n - i >= 0:
                    v += a * c[n - i]
            c.append(v)
        self.assertEqual(c, [bs.quasi_leaf_size(d) for d in range(21)])
        # level series (1 - x)^2/(1 - 3x + x^2)
        h = []
        num = {0: 1, 1: -2, 2: 1}
        for n in range(21):
            v = num.get(n, 0) + (3 * h[n - 1] if n >= 1 else 0) - (h[n - 2] if n >= 2 else 0)
            h.append(v)
        self.assertEqual(h, [bs.quasi_level_size(d) for d in range(21)])


class RowMoveTests(unittest.TestCase):
    def test_examples(self):
        self.assertEqual(bs.row_moves((6, 4, 3, 1, 1)), sorted([(5, 5, 3, 2), (5, 3, 3, 2, 1, 1), (5, 4, 3, 1, 1, 1)]))
        self.assertEqual(bs.row_moves((10,)), [(9, 1)])
        self.assertEqual(bs.row_moves((9, 1)), sorted([(8, 2), (8, 1, 1)]))

    def test_properties(self):
        for p in all_partitions(1, 12):
            moves = bs.row_moves(p)
            self.assertIn(bs.step(p), moves)
            for q in moves:
                self.assertTrue(bs.is_partition(q) and sum(q) == sum(p))


class BasinTests(unittest.TestCase):
    def test_periodic_partition(self):
        self.assertEqual(bs.periodic_partition([1, 0, 1, 0]), (4, 2, 2))
        self.assertEqual(bs.periodic_partition([1, 1, 0, 0]), (4, 3, 1))
        self.assertEqual(bs.periodic_partition([0, 0, 0]), (2, 1))
        for beads in ([1, 0, 1, 0, 0], [1, 1, 0, 1, 0, 0]):
            self.assertTrue(bs.is_periodic(bs.periodic_partition(beads)))

    def test_triangular_basin_is_whole_tree(self):
        for n in (6, 10, 15):
            self.assertEqual(bs.basin_level_sizes(bs.periodic_partition([0] * (bs.triangular_root(n) + 1))),
                             bs.level_sizes(n))

    def test_basins_partition_the_partitions(self):
        for n in range(1, 21):
            total = sum(sum(bs.basin_level_sizes(c[0])) for c in bs.cycles(n))
            self.assertEqual(total, bs.partition_number(n), n)

    def test_bw_levels(self):
        expected = {2: [2, 1, 2, 2], 3: [2, 1, 3, 6, 8, 6], 4: [2, 1, 3, 7, 14, 24, 28, 18],
                    5: [2, 1, 3, 7, 15, 32, 60, 92, 96, 54]}
        for ell, levels_ in expected.items():
            self.assertEqual(bs.basin_level_sizes(bs.periodic_partition([1, 0] * ell)), levels_)

    def test_bw_limit_series(self):
        # H_BW(x) = (x-1)^2 (3x+2) / (x^3 - 3x^2 - x + 1) = (2 - x - 4x^2 + 3x^3)/(1 - x - 3x^2 + x^3)
        num = {0: 2, 1: -1, 2: -4, 3: 3}
        c = []
        for k in range(12):
            c.append(num.get(k, 0) + (c[k - 1] if k >= 1 else 0) + (3 * c[k - 2] if k >= 2 else 0)
                     - (c[k - 3] if k >= 3 else 0))
        self.assertEqual(c[:8], [2, 1, 3, 7, 15, 33, 71, 155])
        for ell in range(2, 9):
            lv = bs.basin_level_sizes(bs.periodic_partition([1, 0] * ell))
            self.assertEqual(lv[:ell], c[:ell], ell)
            self.assertEqual(len(lv), 2 * ell, ell)


if __name__ == "__main__":
    unittest.main()
