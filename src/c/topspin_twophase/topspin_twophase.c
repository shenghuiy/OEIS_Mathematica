/* A two-phase (Kociemba-style) solver for the 20-token TopSpin puzzle, behind
   TopSpinSolve[state, Method -> "TwoPhase"] in src/wolfram/TopSpin.wl.  See docs/TopSpinTwoPhase.md.

   States and moves.  s[P] is the label (0..19) in position P (0..19), and the solved state is
   s[P] = P.  Move m = 0 is F, which reverses positions 0..3; m = 1..19 is R^m, which rotates the
   track right by m.  Applying m to s gives t[P] = s[rho_m(P)], so the token in position P moves to
   P + m for R^m, and 0 <-> 3, 1 <-> 2 for F.  Steps are counted with each R^m as one step
   ("CompressRotations" -> True), and elementary moves with R^m as min(m, 20 - m) moves.

   Phase 2 works in H = <R^2, F>, of order 2 * 10! = 7,257,600.  Tokens move in H as rigid pairs
   in the slots {2j, 2j + 1}.  With eps(l) = bit 0 of l xor bit 1 of l, a state is in H when every
   slot holds a label pair (s[2j + 1] = s[2j] xor 1) and eps(s[2j]) xor (j & 1) is the same for all
   j.  A breadth-first search over H with the moves R^2, R^4, ..., R^18 and F stores every
   element's distance (D2) and the fewest elementary moves among the shortest words (E2).

   Phase 1 brings the state into H, or into H R, from which an odd rotation enters H.  Its
   states are the cosets H s.  H relabels the labels, so the coset of s is the matching of the
   positions that hold the same label pair, together with the coloring P -> eps(s[P]) up to
   complementing every color: 654,729,075 matchings times 512 colorings, 3.35 * 10^11 cosets.
   Phase-1 words alternate a rotation and F and end with F.  An "A state" is one reached by such
   a word, where the next move is a rotation or the word stops.  IDA* searches A states two steps
   at a time (a rotation, then F), with three lower bounds:
     - the coloring alone (184,756 colorings, a 2^20-byte table indexed by the color-1 mask),
     - the matching with one more bit, the parity below (2 * 654,729,075 entries of 4 bits,
       built in about 2 minutes on 16 threads and cached in a file),
     - the exact distance of every coset within 16 steps of the goal (45,780,118 cosets in a
       2^27-entry hash table, built in about 3 s); a coset outside it is at least 18 away.
   Like Kociemba's solver, the search does not stop at the shortest phase 1: for each phase-1
   length it finds every phase-1 solution of exactly that length and completes it with phase 2
   by table lookup, and it goes on to longer phase 1 until the time runs out or the phase-1
   length reaches the best total.  It can also solve variants of the position (relabeled, the
   inverse, the mirror image), interleaving their bounds, and keep the best. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _OPENMP
#include <omp.h>
#else
static int omp_get_thread_num(void) { return 0; }
static int omp_get_max_threads(void) { return 1; }
#endif

#if defined(_MSC_VER)
#include <intrin.h>
#include <windows.h>
#define TSTP_EXPORT __declspec(dllexport)
static int ctz32(uint32_t x) { unsigned long i; _BitScanForward(&i, x); return (int)i; }
static int popc32(uint32_t x) { return (int)__popcnt(x); }
static int cas64(volatile uint64_t *p, uint64_t old, uint64_t v) {
  return (uint64_t)_InterlockedCompareExchange64((volatile long long *)p, (long long)v, (long long)old) == old;
}
#define PREFETCH(p) _mm_prefetch((const char *)(p), _MM_HINT_T0)
static double nowMs(void) {
  static LARGE_INTEGER f; LARGE_INTEGER c;
  if (!f.QuadPart) QueryPerformanceFrequency(&f);
  QueryPerformanceCounter(&c);
  return 1000.0 * (double)c.QuadPart / (double)f.QuadPart;
}
#else
#include <time.h>
#define TSTP_EXPORT __attribute__((visibility("default")))
static int ctz32(uint32_t x) { return __builtin_ctz(x); }
static int popc32(uint32_t x) { return __builtin_popcount(x); }
static int cas64(volatile uint64_t *p, uint64_t old, uint64_t v) {
  return __atomic_compare_exchange_n(p, &old, v, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}
#define PREFETCH(p) __builtin_prefetch(p)
static double nowMs(void) {
  struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
  return 1e3 * (double)t.tv_sec + 1e-6 * (double)t.tv_nsec;
}
#endif

#define HSIZE 7257600
#define MSIZE 654729075
#define BALL_RADIUS 16
#define BALL_BITS 27
#define INF 1000
#define MAXTASK 20000

static uint8_t *D2, *E2, *colA;
static uint64_t *ball;
static const uint64_t ballCap = 1ull << BALL_BITS;
static long long ballCount;
static uint8_t pm[20][20];     /* pm[m][P]: the position the token in P moves to under move m */
static uint8_t pmRF[20][20];   /* the same for R^m followed by F */
static int tailL[10];          /* the label of pair k with color 1 */
static int nThreads = 1, ready = 0;

static int elemOf(int m) { return m == 0 ? 1 : (m <= 10 ? m : 20 - m); }
static int eps(int l) { return (l ^ (l >> 1)) & 1; }

static void applyS(const uint8_t *s, uint8_t *t, int m) {
  if (m == 0) { t[0] = s[3]; t[1] = s[2]; t[2] = s[1]; t[3] = s[0]; memcpy(t + 4, s + 4, 16); }
  else for (int p = 0; p < 20; p++) t[p] = s[(p - m + 20) % 20];
}

static void initMoves(void) {
  for (int m = 0; m < 20; m++) for (int p = 0; p < 20; p++)
    pm[m][p] = (uint8_t)(m == 0 ? (p < 4 ? 3 - p : p) : (p + m) % 20);
  for (int m = 0; m < 20; m++) for (int p = 0; p < 20; p++) pmRF[m][p] = pm[0][pm[m][p]];
  for (int k = 0; k < 10; k++) tailL[k] = eps(2 * k) ? 2 * k : 2 * k + 1;
}

/* ---------- Phase 2: the table over H ---------- */

static int inH(const uint8_t *s) {
  int c = eps(s[0]);
  for (int j = 0; j < 10; j++) {
    if (s[2 * j + 1] != (s[2 * j] ^ 1)) return 0;
    if ((eps(s[2 * j]) ^ (j & 1)) != c) return 0;
  }
  return 1;
}

/* The pairs' order as a permutation of 10 (Lehmer code), and the constant above. */
static int hrank(const uint8_t *s) {
  int r = 0; uint32_t used = 0;
  for (int j = 0; j < 10; j++) {
    int v = s[2 * j] >> 1;
    r = r * (10 - j) + v - popc32(used & ((1u << v) - 1));
    used |= 1u << v;
  }
  return 2 * r + eps(s[0]);
}

static void hunrank(int idx, uint8_t *s) {
  int c = idx & 1, r = idx >> 1, dig[10];
  for (int j = 9; j >= 0; j--) { dig[j] = r % (10 - j); r /= (10 - j); }
  uint32_t used = 0;
  for (int j = 0; j < 10; j++) {
    int k = dig[j], v;
    for (v = 0;; v++) if (!((used >> v) & 1)) { if (k == 0) break; k--; }
    used |= 1u << v;
    int o = c ^ (v & 1) ^ (j & 1);
    s[2 * j] = (uint8_t)(2 * v + o); s[2 * j + 1] = (uint8_t)(2 * v + 1 - o);
  }
}

static const int gens2[10] = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18};

static void buildPhase2(void) {
  uint8_t s[20];
  memset(D2, 255, HSIZE); memset(E2, 255, HSIZE);
  for (int i = 0; i < 20; i++) s[i] = (uint8_t)i;
  int id = hrank(s), d, maxd;
  D2[id] = 0; E2[id] = 0;
  for (d = 0;; d++) {
    long long cnt = 0;
    int idx;
#pragma omp parallel for reduction(+:cnt) schedule(dynamic, 65536)
    for (idx = 0; idx < HSIZE; idx++) if (D2[idx] == d) {
      uint8_t a[20], t[20];
      hunrank(idx, a);
      for (int g = 0; g < 10; g++) {
        applyS(a, t, gens2[g]);
        int j = hrank(t);
        if (D2[j] == 255) { D2[j] = (uint8_t)(d + 1); cnt++; }
      }
    }
    if (!cnt) break;
  }
  maxd = d;
  for (d = 1; d <= maxd; d++) {
    int idx;
#pragma omp parallel for schedule(dynamic, 65536)
    for (idx = 0; idx < HSIZE; idx++) if (D2[idx] == d) {
      uint8_t a[20], t[20]; int best = 255;
      hunrank(idx, a);
      for (int g = 0; g < 10; g++) {
        applyS(a, t, gens2[g]);
        int j = hrank(t);
        if (D2[j] == d - 1 && elemOf(gens2[g]) + E2[j] < best) best = elemOf(gens2[g]) + E2[j];
      }
      E2[idx] = (uint8_t)best;
    }
  }
}

/* ---------- Phase 1 bound: the coloring ---------- */

/* x has bit P set when position P has color 1. */
static uint32_t maskMove(uint32_t x, int m) {
  if (m == 0) {
    uint32_t lo = x & 15;
    return (x & ~15u) | ((lo & 1) << 3) | ((lo & 2) << 1) | ((lo & 4) >> 1) | ((lo & 8) >> 3);
  }
  return ((x << m) | (x >> (20 - m))) & 0xFFFFF;
}

/* The goal colorings: H (0x66666) and H R (0xCCCCC), each with its complement.  B states come
   after a rotation and must take F next; only A states can stop. */
static void buildColor(void) {
  static const uint32_t goal[4] = {0x66666, 0x99999, 0xCCCCC, 0x33333};
  uint8_t *colB = malloc(1 << 20);
  memset(colA, 255, 1 << 20); memset(colB, 255, 1 << 20);
  for (int i = 0; i < 4; i++) colA[goal[i]] = 0;
  for (int d = 1;; d++) {
    long long cnt = 0;
    for (uint32_t x = 0; x < (1u << 20); x++) {
      if (popc32(x) != 10) continue;
      if (colA[x] == d - 1) { uint32_t y = maskMove(x, 0); if (colB[y] == 255) { colB[y] = (uint8_t)d; cnt++; } }
      if (colB[x] == d - 1) for (int r = 1; r < 20; r++) {
        uint32_t z = maskMove(x, 20 - r);
        if (colA[z] == 255) { colA[z] = (uint8_t)d; cnt++; }
      }
    }
    if (!cnt) break;
  }
  free(colB);
}

/* ---------- Phase 1 bound: the matching and its parity ---------- */

/* partner[P] is the position matched with P.  The rank takes the lowest unmatched position in
   turn; its digit is the partner's place among the positions still unmatched (19 * 17 * ... * 1). */
static int mrank(const uint8_t *partner) {
  uint32_t rem = 0xFFFFF; int r = 0;
  for (int k = 0; k < 10; k++) {
    int i = ctz32(rem); rem &= ~(1u << i);
    int p = partner[i];
    r = r * (19 - 2 * k) + popc32(rem & ((1u << p) - 1));
    rem &= ~(1u << p);
  }
  return r;
}

static void munrank(int r, uint8_t *partner) {
  int dig[10];
  for (int k = 9; k >= 0; k--) { int b = 19 - 2 * k; dig[k] = r % b; r /= b; }
  uint32_t rem = 0xFFFFF;
  for (int k = 0; k < 10; k++) {
    int i = ctz32(rem); rem &= ~(1u << i);
    uint32_t x = rem;
    for (int j = 0; j < dig[k]; j++) x &= x - 1;
    int p = ctz32(x); rem &= ~(1u << p);
    partner[i] = (uint8_t)p; partner[p] = (uint8_t)i;
  }
}

static void mmove(const uint8_t *a, uint8_t *b, int m) {
  for (int p = 0; p < 20; p++) b[pm[m][p]] = pm[m][a[p]];
}

/* The parity of a state is the number of label pairs whose odd label is in the lower of their two
   positions, mod 2.  Relabeling by H keeps it, so the matching with its parity is a coarser coset
   (of the subgroup of pair permutations that reverse an even number of pairs): 2 * 654,729,075 of
   them.  A move changes the parity once for each matched pair whose positions it puts in the other
   order, which mmoveP returns.  The goals are (the matching of H, parity 0) and (the matching of
   H R, parity 1).  Swapping the two tokens of one pair gives (the matching of H, parity 1), which
   is 36 steps away, while its matching alone is the goal's. */

static int mmoveP(const uint8_t *a, uint8_t *b, int m) {
  int flips = 0;
  for (int p = 0; p < 20; p++) {
    b[pm[m][p]] = pm[m][a[p]];
    if (p < a[p] && pm[m][p] > pm[m][a[p]]) flips ^= 1;
  }
  return flips;
}

/* Half the A distance, 4 bits for each (matching, parity), with both parities of a matching in one
   byte.  15 stands for 30 or more; the 4,010 entries above 30 are in a sorted list. */
static uint8_t *pairT, *pairExcVal;
static uint64_t *pairExcKey;
static int nPairExc;

static int pairDist(int mr, int par) {
  int v = (pairT[mr] >> (4 * par)) & 15, lo = 0, hi = nPairExc - 1;
  uint64_t key = 2 * (uint64_t)mr + par;
  if (v < 15) return 2 * v;
  while (lo <= hi) {
    int mid = (lo + hi) / 2;
    if (pairExcKey[mid] == key) return pairExcVal[mid];
    if (pairExcKey[mid] < key) lo = mid + 1; else hi = mid - 1;
  }
  return 30;
}

/* An A state x is 2 + the least distance of F R^r x, r = 1..19.  The layers are found forward,
   from the predecessors of the last layer, until half the states are reached, and then backward:
   an unreached state joins layer d + 2 when one of its 19 successors is in layer d.  Returns 0
   when memory runs out. */
static int buildPairing(void) {
  const long long total = 2ll * MSIZE;
  uint8_t *T = malloc(total), a[20];
  long long reached = 2, r;
  if (!T) return 0;
  memset(T, 255, total);
  for (int j = 0; j < 10; j++) { a[2 * j] = (uint8_t)(2 * j + 1); a[2 * j + 1] = (uint8_t)(2 * j); }
  T[2ll * mrank(a)] = 0;
  for (int j = 0; j < 10; j++) { int p = 2 * j + 1, q = (2 * j + 2) % 20; a[p] = (uint8_t)q; a[q] = (uint8_t)p; }
  T[2ll * mrank(a) + 1] = 0;
  for (int d = 0;; d += 2) {
    long long cnt = 0;
    if (reached < total / 2) {
#pragma omp parallel for reduction(+:cnt) schedule(dynamic, 65536)
      for (r = 0; r < total; r++) if (T[r] == d) {
        uint8_t y[20], z[20], x[20];
        munrank((int)(r >> 1), y);
        int par = (int)(r & 1) ^ mmoveP(y, z, 0);
        for (int rot = 1; rot < 20; rot++) {
          int px = par ^ mmoveP(z, x, 20 - rot);
          long long rr = 2ll * mrank(x) + px;
          if (T[rr] == 255) { T[rr] = (uint8_t)(d + 2); cnt++; }
        }
      }
    } else {
#pragma omp parallel for reduction(+:cnt) schedule(dynamic, 65536)
      for (r = 0; r < total; r++) if (T[r] == 255) {
        uint8_t x[20], z[20], y[20];
        munrank((int)(r >> 1), x);
        for (int rot = 1; rot < 20; rot++) {
          int pz = (int)(r & 1) ^ mmoveP(x, z, rot);
          int py = pz ^ mmoveP(z, y, 0);
          if (T[2ll * mrank(y) + py] == d) { T[r] = (uint8_t)(d + 2); cnt++; break; }
        }
      }
    }
    if (!cnt) break;
    reached += cnt;
  }
  nPairExc = 0;
  for (r = 0; r < total; r++) if (T[r] > 30) nPairExc++;
  pairExcKey = malloc((nPairExc + 1) * sizeof(uint64_t)); pairExcVal = malloc(nPairExc + 1);
  if (!pairExcKey || !pairExcVal) { free(T); return 0; }
  nPairExc = 0;
  for (r = 0; r < total; r++) if (T[r] > 30) { pairExcKey[nPairExc] = (uint64_t)r; pairExcVal[nPairExc++] = T[r]; }
  for (r = 0; r < MSIZE; r++) {
    int lo = T[2 * r] > 30 ? 15 : T[2 * r] / 2, hi = T[2 * r + 1] > 30 ? 15 : T[2 * r + 1] / 2;
    pairT[r] = (uint8_t)(lo | (hi << 4));
  }
  free(T);
  return 1;
}

/* The cache file holds pairT, then the number of entries above 30, their keys and their values. */
static int readPairing(const char *name) {
  FILE *f = fopen(name, "rb");
  int ok = 0;
  if (!f) return 0;
  if (fread(pairT, 1, MSIZE, f) == MSIZE && fread(&nPairExc, sizeof nPairExc, 1, f) == 1 &&
      nPairExc >= 0 && nPairExc < 1000000) {
    pairExcKey = malloc((nPairExc + 1) * sizeof(uint64_t)); pairExcVal = malloc(nPairExc + 1);
    ok = pairExcKey && pairExcVal &&
         fread(pairExcKey, sizeof(uint64_t), nPairExc, f) == (size_t)nPairExc &&
         fread(pairExcVal, 1, nPairExc, f) == (size_t)nPairExc && fgetc(f) == EOF;
  }
  fclose(f);
  if (!ok) { free(pairExcKey); free(pairExcVal); pairExcKey = NULL; pairExcVal = NULL; }
  return ok;
}

static void writePairing(const char *name) {
  FILE *f = fopen(name, "wb");
  if (!f) return;
  fwrite(pairT, 1, MSIZE, f);
  fwrite(&nPairExc, sizeof nPairExc, 1, f);
  fwrite(pairExcKey, sizeof(uint64_t), nPairExc, f);
  fwrite(pairExcVal, 1, nPairExc, f);
  fclose(f);
}

/* ---------- Phase 1 bound: exact distances near the goal ---------- */

/* The key of a coset is its matching rank and its color-1 mask, complemented if needed so that
   position 0 has color 0.  Entries are key | distance << 56; 0 is empty. */

static uint64_t ballSlot(uint64_t key) { return (key * 0x9E3779B97F4A7C15ull) >> (64 - BALL_BITS); }

static uint64_t cosetKey(int mr, uint32_t mask) {
  if (mask & 1) mask = ~mask & 0xFFFFF;
  return ((uint64_t)mr << 20) | mask;
}

static int ballGet(uint64_t key) {
  uint64_t i = ballSlot(key);
  for (;;) {
    uint64_t e = ball[i];
    if (!e) return -1;
    if ((e & ((1ull << 56) - 1)) == key) return (int)(e >> 56);
    i = (i + 1) & (ballCap - 1);
  }
}

static int ballPut(uint64_t key, int d) {
  uint64_t i = ballSlot(key), v = key | ((uint64_t)d << 56);
  for (;;) {
    uint64_t e = ball[i];
    if (!e) {
      if (cas64((volatile uint64_t *)&ball[i], 0, v)) return 1;
      e = ball[i];
    }
    if ((e & ((1ull << 56) - 1)) == key) return 0;
    i = (i + 1) & (ballCap - 1);
  }
}

typedef struct { uint64_t *a; long long n, cap; } KeyList;

static int klPush(KeyList *l, uint64_t k) {
  if (l->n == l->cap) {
    long long c = l->cap ? 2 * l->cap : 1 << 16;
    uint64_t *a = realloc(l->a, c * sizeof(uint64_t));
    if (!a) return 0;
    l->a = a; l->cap = c;
  }
  l->a[l->n++] = k;
  return 1;
}

static int buildBall(void) {
  KeyList cur = {0}, next[256];
  uint8_t a[20];
  int ok = 1, nt = omp_get_max_threads();
  if (nt > 256) nt = 256;
  memset(ball, 0, ballCap * sizeof(uint64_t));
  for (int j = 0; j < 10; j++) { a[2 * j] = (uint8_t)(2 * j + 1); a[2 * j + 1] = (uint8_t)(2 * j); }
  uint64_t k0 = cosetKey(mrank(a), 0x66666);
  for (int j = 0; j < 10; j++) { int p = 2 * j + 1, q = (2 * j + 2) % 20; a[p] = (uint8_t)q; a[q] = (uint8_t)p; }
  uint64_t k1 = cosetKey(mrank(a), 0xCCCCC);
  ballPut(k0, 0); ballPut(k1, 0);
  klPush(&cur, k0); klPush(&cur, k1);
  ballCount = 2;
  for (int d = 0; d + 2 <= BALL_RADIUS && ok; d += 2) {
    long long i;
    memset(next, 0, sizeof next);
#pragma omp parallel for schedule(dynamic, 4096) num_threads(nt)
    for (i = 0; i < cur.n; i++) {
      KeyList *mine = &next[omp_get_thread_num()];
      uint8_t y[20], z[20], x[20];
      uint64_t key = cur.a[i];
      munrank((int)(key >> 20), y);
      uint32_t zm = maskMove((uint32_t)(key & 0xFFFFF), 0);
      mmove(y, z, 0);
      for (int rot = 1; rot < 20; rot++) {
        mmove(z, x, 20 - rot);
        uint64_t kk = cosetKey(mrank(x), maskMove(zm, 20 - rot));
        if (ballPut(kk, d + 2) && !klPush(mine, kk)) ok = 0;
      }
    }
    free(cur.a); memset(&cur, 0, sizeof cur);
    for (int t = 0; t < nt; t++) {
      for (long long j = 0; j < next[t].n && ok; j++) ok = klPush(&cur, next[t].a[j]);
      free(next[t].a);
    }
    ballCount += cur.n;
  }
  free(cur.a);
  return ok;
}

/* ---------- Phase 1 search ---------- */

/* Node budgets of the reproducible search (limitMs < 0): per phase-1 length and variant, shared
   equally by the tasks, and in all before a first solution. */
#define BOUND_BUDGET 100000000LL
#define TOTAL_BUDGET 400000000LL

static int bound1;
static volatile int timeUp, haveSol;
static double deadline;
static long long statNodes, statSols;

typedef struct {
  int path[64], bestPath[64], bestSteps, bestElem, bestLen1, bestRot;
  long long nodes, nsol, taskNodes, budget;
  int stop;
} Ctx;

static int mrankPos(const uint8_t *pos) {
  uint8_t pa[20];
  for (int k = 0; k < 10; k++) { pa[pos[2 * k]] = pos[2 * k + 1]; pa[pos[2 * k + 1]] = pos[2 * k]; }
  return mrank(pa);
}

static uint32_t maskPos(const uint8_t *pos) {
  uint32_t mask = 0;
  for (int k = 0; k < 10; k++) mask |= 1u << pos[tailL[k]];
  return mask;
}

static int parPos(const uint8_t *pos) {
  int par = 0;
  for (int k = 0; k < 10; k++) par ^= pos[2 * k + 1] < pos[2 * k];
  return par;
}

/* Lower bound for an A state: exact inside the ball, else the larger table value, at least 18. */
static int hA1(const uint8_t *pos) {
  int mr = mrankPos(pos), d = ballGet(cosetKey(mr, maskPos(pos))), m;
  if (d >= 0) return d;
  int h = colA[maskPos(pos)];
  m = pairDist(mr, parPos(pos));
  if (m > h) h = m;
  if (h < BALL_RADIUS + 2) h = BALL_RADIUS + 2;
  return h;
}

/* A phase-1 solution of length g: complete it from H directly, or through an odd rotation from H R. */
static void evaluate(Ctx *c, const uint8_t *pos, int g, int elem1) {
  uint8_t s[20], t[20];
  for (int l = 0; l < 20; l++) s[pos[l]] = (uint8_t)l;
  int steps = INF, el = INF, rot = -1;
  if (inH(s)) { int i = hrank(s); steps = g + D2[i]; el = elem1 + E2[i]; rot = 0; }
  else {
    applyS(s, t, 1);
    if (!inH(t)) return;
    for (int r = 1; r < 20; r += 2) {
      applyS(s, t, r);
      int i = hrank(t), st = g + 1 + D2[i], e = elem1 + elemOf(r) + E2[i];
      if (st < steps || (st == steps && e < el)) { steps = st; el = e; rot = r; }
    }
  }
  c->nsol++;
  haveSol = 1;
  if (steps < c->bestSteps || (steps == c->bestSteps && el < c->bestElem)) {
    c->bestSteps = steps; c->bestElem = el; c->bestRot = rot; c->bestLen1 = g;
    memcpy(c->bestPath, c->path, g * sizeof(int));
  }
}

static const int rotOrder[19] = {1, 19, 2, 18, 3, 17, 4, 16, 5, 15, 6, 14, 7, 13, 8, 12, 9, 11, 10};

/* An A state at depth g: the next two steps are a rotation and F, or the word stops at bound1. */
static void dfsA(Ctx *c, const uint8_t *pos, int g, int elem1) {
  if ((++c->nodes & 255) == 0) {
    double tn = nowMs();
    if ((haveSol && tn > deadline) || tn > deadline + 20000) timeUp = 1;
  }
  if (c->budget && ++c->taskNodes > c->budget) c->stop = 1;
  if (timeUp || c->stop) return;
  if (g == bound1) { evaluate(c, pos, g, elem1); return; }
  int rem = bound1 - g - 2;
  if (rem < 0) return;
  uint8_t np[19][20]; int hv[19];
  if (rem <= BALL_RADIUS) {
    uint64_t key[19];
    for (int i = 0; i < 19; i++) {
      const uint8_t *t = pmRF[rotOrder[i]];
      for (int l = 0; l < 20; l++) np[i][l] = t[pos[l]];
      key[i] = cosetKey(mrankPos(np[i]), maskPos(np[i]));
      PREFETCH(&ball[ballSlot(key[i])]);
    }
    for (int i = 0; i < 19; i++) { int d = ballGet(key[i]); hv[i] = d < 0 ? INF : d; }
  } else {
    int mr[19];
    for (int i = 0; i < 19; i++) {
      const uint8_t *t = pmRF[rotOrder[i]];
      for (int l = 0; l < 20; l++) np[i][l] = t[pos[l]];
      mr[i] = mrankPos(np[i]);
      PREFETCH(&pairT[mr[i]]);
    }
    for (int i = 0; i < 19; i++) {
      int h = colA[maskPos(np[i])], m = pairDist(mr[i], parPos(np[i]));
      hv[i] = m > h ? m : h;
    }
  }
  for (int i = 0; i < 19; i++) {
    if (hv[i] > rem) continue;
    int r = rotOrder[i];
    c->path[g] = r; c->path[g + 1] = 0;
    dfsA(c, np[i], g + 2, elem1 + elemOf(r) + 1);
  }
}

/* A task is a subtree near the root.  Each keeps its own best, and the bests are merged in task
   order, so a search that finishes its bounds gives the same answer on any number of threads. */
typedef struct {
  uint8_t pos[20]; int g, elem1, path[16];
  int bestSteps, bestElem, bestLen1, bestRot, bestPath[64];
  long long nodes;
} Task;

static Task *tasks, *nx;
static Ctx *ctxs;

typedef struct { int steps, elem, variant, len1, rot, path[64]; } Best;

/* With a budget, each task stops after its share of it, so the result does not depend on the
   threads; returns the nodes searched. */
static long long searchBound(const uint8_t *pos0, int variant, Best *best, long long budget) {
  int n = 0, k;
  if (bound1 % 2 == 0) {
    if (hA1(pos0) <= bound1) { memcpy(tasks[0].pos, pos0, 20); tasks[0].g = 0; tasks[0].elem1 = 0; n = 1; }
  } else {
    uint8_t y[20];
    for (int l = 0; l < 20; l++) y[l] = pm[0][pos0[l]];
    if (1 + hA1(y) <= bound1) { memcpy(tasks[0].pos, y, 20); tasks[0].g = 1; tasks[0].elem1 = 1; tasks[0].path[0] = 0; n = 1; }
  }
  /* split into enough tasks, staying above the ball */
  while (n > 0 && n < 512 && tasks[0].g + 2 < 14 && bound1 - tasks[0].g - 2 > BALL_RADIUS + 2) {
    int m = 0;
    for (k = 0; k < n; k++) {
      Task *t = &tasks[k];
      for (int i = 0; i < 19; i++) {
        int r = rotOrder[i];
        Task *u = &nx[m];
        for (int l = 0; l < 20; l++) u->pos[l] = pmRF[r][t->pos[l]];
        if (t->g + 2 + hA1(u->pos) > bound1) continue;
        memcpy(u->path, t->path, t->g * sizeof(int));
        u->path[t->g] = r; u->path[t->g + 1] = 0;
        u->g = t->g + 2; u->elem1 = t->elem1 + elemOf(r) + 1;
        m++;
      }
    }
    memcpy(tasks, nx, m * sizeof(Task)); n = m;
  }
  long long share = budget > 0 && n > 0 ? (budget + n - 1) / n : 0, used = 0;
#pragma omp parallel for schedule(dynamic, 1) num_threads(nThreads)
  for (k = 0; k < n; k++) {
    Ctx *c = &ctxs[omp_get_thread_num()];
    Task *t = &tasks[k];
    c->bestSteps = INF; c->bestElem = INF;
    c->budget = share; c->taskNodes = 0; c->stop = 0;
    memcpy(c->path, t->path, t->g * sizeof(int));
    dfsA(c, t->pos, t->g, t->elem1);
    t->nodes = c->taskNodes;
    t->bestSteps = c->bestSteps; t->bestElem = c->bestElem;
    if (c->bestSteps < INF) {
      t->bestLen1 = c->bestLen1; t->bestRot = c->bestRot;
      memcpy(t->bestPath, c->bestPath, c->bestLen1 * sizeof(int));
    }
  }
  for (k = 0; k < n; k++) {
    Task *t = &tasks[k];
    used += t->nodes;
    if (t->bestSteps < best->steps || (t->bestSteps == best->steps && t->bestElem < best->elem)) {
      best->steps = t->bestSteps; best->elem = t->bestElem; best->variant = variant;
      best->len1 = t->bestLen1; best->rot = t->bestRot;
      memcpy(best->path, t->bestPath, t->bestLen1 * sizeof(int));
    }
  }
  return used;
}

/* Variants, by bit: 1 relabels every token l as l + 1 (mod 20), which pairs the tokens 20 and 1,
   2 and 3, ... instead, so phase 1 sees a different coset; its solution followed by R^19 solves
   the position.  2 is the inverse position: its solution, reversed with R^r -> R^(20 - r), solves
   the position.  4 is the mirror image under P -> 3 - P (mod 20), which fixes F and turns R^r
   into R^(20 - r). */
static void variantState(const uint8_t *s0, int v, uint8_t *s) {
  uint8_t a[20], b[20];
  if (v & 2) for (int p = 0; p < 20; p++) a[s0[p]] = (uint8_t)p; else memcpy(a, s0, 20);
  if (v & 4) for (int p = 0; p < 20; p++) b[p] = (uint8_t)((23 - a[(23 - p) % 20]) % 20); else memcpy(b, a, 20);
  for (int p = 0; p < 20; p++) s[p] = (uint8_t)((v & 1) ? (b[p] + 1) % 20 : b[p]);
}

static int variantWord(int v, int *w, int n) {
  if (v & 1) {
    if (n > 0 && w[n - 1] != 0) { int r = (w[n - 1] + 19) % 20; if (r) w[n - 1] = r; else n--; }
    else w[n++] = 19;
  }
  if (v & 4) for (int i = 0; i < n; i++) if (w[i]) w[i] = 20 - w[i];
  if (v & 2) {
    for (int i = 0; i < n / 2; i++) { int x = w[i]; w[i] = w[n - 1 - i]; w[n - 1 - i] = x; }
    for (int i = 0; i < n; i++) if (w[i]) w[i] = 20 - w[i];
  }
  return n;
}

/* The word of a variant's best solution, turned back into a solution of s0; returns its length. */
static int variantSolution(const uint8_t *s0, const Best *b, int *w) {
  uint8_t s[20], t[20];
  int n = 0, m = 0;
  for (int i = 0; i < b->len1; i++) w[n++] = b->path[i];
  if (b->rot > 0) w[n++] = b->rot;
  variantState(s0, b->variant, s);
  for (int i = 0; i < n; i++) { applyS(s, t, w[i]); memcpy(s, t, 20); }
  for (;;) {
    int i = hrank(s), d = D2[i];
    if (d == 0) break;
    for (int g = 0; g < 10; g++) {
      applyS(s, t, gens2[g]);
      int j = hrank(t);
      if (D2[j] == d - 1 && elemOf(gens2[g]) + E2[j] == E2[i]) { w[n++] = gens2[g]; memcpy(s, t, 20); break; }
    }
  }
  /* merge rotations and cancel F F where phase 1 meets phase 2 */
  for (int i = 0; i < n; i++) {
    int x = w[i];
    if (m > 0 && x != 0 && w[m - 1] != 0) { int r = (w[m - 1] + x) % 20; if (r) w[m - 1] = r; else m--; }
    else if (m > 0 && x == 0 && w[m - 1] == 0) m--;
    else w[m++] = x;
  }
  return variantWord(b->variant, w, m);
}

/* ---------- Library interface ---------- */

TSTP_EXPORT void topspin_tp_free(void) {
  free(D2); free(E2); free(colA); free(pairT); free(pairExcKey); free(pairExcVal);
  free(ball); free(tasks); free(nx); free(ctxs);
  D2 = E2 = colA = pairT = pairExcVal = NULL; pairExcKey = NULL; ball = NULL; tasks = nx = NULL; ctxs = NULL;
  ready = 0;
}

/* Builds the tables; cache, if not NULL or empty, names a file that holds the matching and parity
   table (read when it is there and complete, written after building it).  threads <= 0 uses
   every core.  Returns 0, or -1 when memory runs out. */
TSTP_EXPORT int topspin_tp_init(const char *cache, int threads) {
  if (ready) return 0;
  nThreads = threads > 0 ? threads : omp_get_max_threads();
  if (nThreads > 256) nThreads = 256;
  initMoves();
  D2 = malloc(HSIZE); E2 = malloc(HSIZE); colA = malloc(1 << 20); pairT = malloc(MSIZE);
  tasks = malloc(MAXTASK * sizeof(Task)); nx = malloc(MAXTASK * sizeof(Task));
  ctxs = malloc(256 * sizeof(Ctx));
  if (!D2 || !E2 || !colA || !pairT || !tasks || !nx || !ctxs) { topspin_tp_free(); return -1; }
  buildPhase2();
  buildColor();
  if (!(cache && *cache && readPairing(cache))) {
    if (!buildPairing()) { topspin_tp_free(); return -1; }
    if (cache && *cache) writePairing(cache);
  }
  ball = malloc(ballCap * sizeof(uint64_t));
  if (!ball || !buildBall()) { topspin_tp_free(); return -1; }
  ready = 1;
  return 0;
}

/* Solves state, given 1-based as TopSpinSolve takes it (state[P - 1] is the label in position P).
   out gets the steps: 0 for F, r for R^r (r = 1..19).  limitMs >= 0 stops the search after that
   many milliseconds, once some solution is known.  limitMs = -k searches the phase-1 length of
   the first solution and k - 1 more lengths, each within BOUND_BUDGET nodes per variant, which
   makes the answer the same on any number of threads; it gives up after TOTAL_BUDGET nodes
   without a solution.  variants is 1 to 8: the first that many of the variants 0, 1, ..., 7
   above are searched, with their phase-1 lengths interleaved, and the shortest solution is kept.
   Returns the number of steps, or -1 (not initialized), -2 (not a permutation of 1..20), -3 (no
   solution: 20 s past the limit, or the node budget), -4 (out too short). */
TSTP_EXPORT int topspin_tp_solve(const int *state, double limitMs, int variants, int *out, int outMax) {
  uint8_t s0[20], pos[8][20], s[20];
  int h0[8], lo = INF, firstBound = -1, bestN = -1, bestE = INF, w[256], minSteps = INF;
  long long used = 0, budget = limitMs < 0 ? BOUND_BUDGET : 0;
  uint32_t seen = 0;
  Best bv[8];
  if (!ready) return -1;
  for (int p = 0; p < 20; p++) {
    if (state[p] < 1 || state[p] > 20 || ((seen >> (state[p] - 1)) & 1)) return -2;
    seen |= 1u << (state[p] - 1);
    s0[p] = (uint8_t)(state[p] - 1);
  }
  if (variants < 1) variants = 1;
  if (variants > 8) variants = 8;
  for (int i = 0; i < nThreads; i++) { ctxs[i].nodes = 0; ctxs[i].nsol = 0; }
  timeUp = 0; haveSol = 0;
  deadline = nowMs() + (limitMs >= 0 ? limitMs : 1e12);
  for (int v = 0; v < variants; v++) {
    uint8_t y[20];
    bv[v].steps = INF; bv[v].elem = INF; bv[v].variant = -1;
    variantState(s0, v, s);
    for (int p = 0; p < 20; p++) pos[v][s[p]] = (uint8_t)p;
    for (int l = 0; l < 20; l++) y[l] = pm[0][pos[v][l]];
    int a = hA1(pos[v]), b = 1 + hA1(y);
    h0[v] = a < b ? a : b;
    if (h0[v] < lo) lo = h0[v];
  }
  for (bound1 = lo; bound1 <= minSteps && bound1 < 60 && !timeUp; bound1++) {
    if (limitMs < 0 && firstBound >= 0 && bound1 - firstBound >= -limitMs) break;
    for (int v = 0; v < variants && !timeUp; v++) if (bound1 >= h0[v]) used += searchBound(pos[v], v, &bv[v], budget);
    for (int v = 0; v < variants; v++) if (bv[v].steps < minSteps) minSteps = bv[v].steps;
#ifdef TOPSPIN_TP_MAIN
    if (getenv("TOPSPIN_TP_DEBUG")) fprintf(stderr, "  bound %d (roots %d %d): %lld nodes, best %d\n", bound1, h0[0], variants > 1 ? h0[1] : -1, used, minSteps);
#endif
    if (minSteps < INF && firstBound < 0) firstBound = bound1;
    if (budget && firstBound < 0 && used >= TOTAL_BUDGET) break;
  }
  statNodes = 0; statSols = 0;
  for (int i = 0; i < nThreads; i++) { statNodes += ctxs[i].nodes; statSols += ctxs[i].nsol; }
  if (firstBound < 0 && limitMs < 0) return -3;
  /* the relabeled variants end with an extra rotation, so compare the finished words */
  for (int v = 0; v < variants; v++) {
    if (bv[v].variant < 0) continue;
    int x[256], n = variantSolution(s0, &bv[v], x), e = 0;
    for (int i = 0; i < n; i++) e += elemOf(x[i]);
    if (bestN < 0 || n < bestN || (n == bestN && e < bestE)) { bestN = n; bestE = e; memcpy(w, x, n * sizeof(int)); }
  }
  if (bestN < 0) return -3;
  if (bestN > outMax) return -4;
  memcpy(out, w, bestN * sizeof(int));
  return bestN;
}

/* nodes searched and phase-1 solutions completed by the last solve */
TSTP_EXPORT void topspin_tp_stats(long long *out) { out[0] = statNodes; out[1] = statSols; out[2] = ballCount; }

#ifdef TOPSPIN_TP_MAIN
/* Benchmark: topspin_twophase positions.txt variants limit... reads 20 labels per position and
   prints the averages for each limit (in ms; -k for k whole phase-1 lengths). */
int main(int argc, char **argv) {
  static int P[1000][20];
  int np = 0, variants = argc > 2 ? atoi(argv[2]) : 1;
  double t0 = nowMs();
  if (argc < 4) { fprintf(stderr, "usage: %s positions.txt variants limit...\n", argv[0]); return 1; }
  setvbuf(stdout, NULL, _IONBF, 0);
  if (topspin_tp_init(getenv("TOPSPIN_TP_CACHE"), 0)) { fprintf(stderr, "out of memory\n"); return 1; }
  printf("tables: %.1f s, %lld cosets near the goal, %d threads\n", (nowMs() - t0) / 1000, ballCount, nThreads);
  FILE *f = fopen(argv[1], "r");
  if (!f) { fprintf(stderr, "cannot read %s\n", argv[1]); return 1; }
  while (np < 1000) {
    int ok = 1;
    for (int p = 0; p < 20 && ok; p++) ok = fscanf(f, "%d", &P[np][p]) == 1;
    if (!ok) break;
    np++;
  }
  fclose(f);
  for (int li = 3; li < argc; li++) {
    double lim = atof(argv[li]), tsum = 0, tmax = 0;
    long long ssum = 0, esum = 0, fsum = 0, nmax = 0; int smax = 0, emax = 0, bad = 0;
    char name[64]; sprintf(name, "tp_v%d_%s.txt", variants, argv[li]);
    FILE *o = fopen(name, "w");
    for (int i = 0; i < np; i++) {
      int w[256], el = 0, fl = 0;
      double a = nowMs();
      int n = topspin_tp_solve(P[i], lim, variants, w, 256);
      double b = nowMs() - a;
      if (statNodes > nmax) nmax = statNodes;
      if (n < 0) { bad++; continue; }
      uint8_t s[20], t[20];
      for (int p = 0; p < 20; p++) s[p] = (uint8_t)(P[i][p] - 1);
      for (int k = 0; k < n; k++) { applyS(s, t, w[k]); memcpy(s, t, 20); el += elemOf(w[k]); fl += w[k] == 0; }
      for (int p = 0; p < 20; p++) if (s[p] != p) { bad++; break; }
      ssum += n; esum += el; fsum += fl;
      if (n > smax) smax = n;
      if (el > emax) emax = el;
      tsum += b; if (b > tmax) tmax = b;
      if (o) { fprintf(o, "%d %d %d %.3f", n, el, fl, b); for (int k = 0; k < n; k++) fprintf(o, " %d", w[k]); fprintf(o, "\n"); }
    }
    if (o) fclose(o);
    printf("variants %d, limit %s: steps %.2f (max %d), elementary %.2f (max %d), flips %.2f, %.1f ms per solve (max %.0f), nodes max %lld, failures %d\n",
           variants, argv[li], (double)ssum / np, smax, (double)esum / np, emax, (double)fsum / np, tsum / np, tmax, nmax, bad);
  }
  topspin_tp_free();
  return 0;
}
#endif
