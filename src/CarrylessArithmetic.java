/*

              PROGRAM FOR DISMAL ARITHMETIC

  David Applegate (david(AT)research.att.com), Nov 11 2003
  Java translation of the original C program (main() omitted).

 *************************************************************************

DESCRIPTION

Dismal arithmetic was invented by Marc LeBrun in 2003.
It is now usually called "lunar" or carry-less arithmetic.

The operations of dismal addition and dismal multiplication are
described in sequences A087061 (addition) and A087062 (multiplication)
in the On-Line Encyclopedia of Integer Sequences.

Numbers are represented as decimal digit strings ("0".."9").

Available operations (public static methods):
   dismalDivide(a, b, cb)   Reports every c such that b*c = a
   dismalDivisors(a, cb)    Reports every b such that b*c = a for some c
   dismalAdd(a, b)          Returns a+b
   dismalMul(a, b)          Returns a*b
   pCountRange(a, b)        Counts the primes in [a,b]
   pPrimesRange(a, b)       Returns the primes in [a,b]
   dinfo(a, b)              Returns info about divisors of n, a<=n<=b
   pdinfo(a, b)             Returns info about prime divisors of n, a<=n<=b
   dinfoRange(a, b, false)  Prints info about divisors of n, a<=n<=b
   dinfoRange(a, b, true)   Prints info about prime divisors of n, a<=n<=b

The callback passed to dismalDivide / dismalDivisors receives each result
once and returns an int; the returned ints are summed and handed back to
the caller.  A negative return value aborts the search.

**************************************************************************
                                           */

import java.math.BigDecimal;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.ToIntFunction;
import java.util.stream.IntStream;
import java.util.stream.LongStream;

public final class CarrylessArithmetic {

    private CarrylessArithmetic() {}

    // Search statistics; LongAdder so parallel searches can update them safely.
    static final LongAdder nFound = new LongAdder();
    static final LongAdder nDeadEnd = new LongAdder();
    static final LongAdder ndup = new LongAdder();

    static final int DIV_PROD_MUL = 16;

    public static String dismalMul(String a, String b) {
        int resLen = a.length() + b.length() - 1;
        char[] res = new char[resLen];
        Arrays.fill(res, '0');

        for (int i = 0; i < a.length(); i++) {
            char ai = a.charAt(i);
            for (int j = 0; j < b.length(); j++) {
                char bj = b.charAt(j);
                if (ai <= bj && ai > res[i + j]) res[i + j] = ai;
                if (bj < ai && bj > res[i + j]) res[i + j] = bj;
            }
        }
        return new String(res);
    }

    public static String dismalAdd(String a, String b) {
        int alen = a.length();
        int blen = b.length();
        StringBuilder res = new StringBuilder(Math.max(alen, blen));
        int ai = 0;
        int bi = 0;

        while (ai < a.length() && alen > blen) {
            res.append(a.charAt(ai++));
            alen--;
        }
        while (bi < b.length() && blen > alen) {
            res.append(b.charAt(bi++));
            blen--;
        }

        while (ai < a.length()) {
            char ca = a.charAt(ai++);
            char cb = b.charAt(bi++);
            res.append(ca > cb ? ca : cb);
        }
        return res.toString();
    }

    /**
     * Enumerates every number whose digit i lies in [min[i], max[i]] for
     * 0 <= i < len, reporting each one not already in reshash.
     */
    private static int spin(char[] res, char[] min, char[] max, int len,
                            Set<String> reshash, int depth,
                            ToIntFunction<String> callback) {
        int nSol = 0;

        if (depth >= len) {
            int start = 0;
            while (start < len && res[start] == '0') start++;
            String s = new String(res, start, len - start);
            if (reshash.add(s)) {
                nFound.increment();
                nSol = callback.applyAsInt(s);
                return nSol;
            } else {
                ndup.increment();
                return 0;
            }
        }

        for (char d = min[depth]; d <= max[depth]; d++) {
            res[depth] = d;
            int rval = spin(res, min, max, len, reshash, depth + 1, callback);
            if (rval < 0) return rval;
            nSol += rval;
        }
        return nSol;
    }

    /** Search state for dismalDivide: the quotient digit ranges and results. */
    private static final class DivideSearch {
        final String num;
        final String den;
        final int numLen;
        final int alen;
        final char[] amin;
        final char[] amax;
        final int[] numorder;
        final char[] res;
        final Set<String> reshash = new HashSet<>();
        final ToIntFunction<String> callback;

        DivideSearch(String num, String den, int resLen, ToIntFunction<String> callback) {
            this.num = num;
            this.den = den;
            this.numLen = num.length();
            this.alen = resLen;
            this.amin = new char[resLen];
            this.amax = new char[resLen];
            this.numorder = new int[numLen];
            this.res = new char[resLen];
            this.callback = callback;
        }

        int work(int depth) {
            int nSol = 0;
            int nCall = 0;

            if (depth >= numLen) {
                return spin(res, amin, amax, alen, reshash, 0, callback);
            }

            int i = numorder[depth];
            char ni = num.charAt(i);

            for (int j = (i >= alen ? i - alen + 1 : 0); j <= i && j < den.length(); j++) {
                char dj = den.charAt(j);
                int k = i - j;
                if (dj > ni && amin[k] <= ni && amax[k] >= ni) {
                    char omin = amin[k];
                    char omax = amax[k];
                    amin[k] = ni;
                    amax[k] = ni;
                    nCall++;
                    int rVal = work(depth + 1);
                    if (rVal < 0) return rVal;
                    nSol += rVal;
                    amin[k] = omin;
                    amax[k] = omax;
                } else if (dj == ni && amax[k] >= ni) {
                    char omin = amin[k];
                    if (omin < ni) amin[k] = ni;
                    nCall++;
                    int rVal = work(depth + 1);
                    if (rVal < 0) return rVal;
                    nSol += rVal;
                    amin[k] = omin;
                }
            }

            if (nCall == 0) nDeadEnd.increment();
            return nSol;
        }
    }

    /** Search state for dismalDivisors: digit ranges of both factors a and b. */
    private static final class DivisorSearch {
        final String num;
        final int numLen;
        int alen;
        int blen;
        final char[] amin;
        final char[] amax;
        final char[] bmin;
        final char[] bmax;
        final int[] numorder;
        final char[] res;
        /** Saved {index, old max} pairs, so max changes can be undone. */
        final Deque<int[]> amaxstack = new ArrayDeque<>();
        final Deque<int[]> bmaxstack = new ArrayDeque<>();
        final Set<String> reshash;
        final ToIntFunction<String> callback;

        DivisorSearch(String num, ToIntFunction<String> callback, Set<String> reshash) {
            this.num = num;
            this.numLen = num.length();
            this.amin = new char[numLen];
            this.amax = new char[numLen];
            this.bmin = new char[numLen];
            this.bmax = new char[numLen];
            this.numorder = new int[numLen + 1];
            this.res = new char[numLen];
            this.callback = callback;
            this.reshash = reshash;

            Arrays.fill(amin, '0');
            Arrays.fill(amax, '9');
            Arrays.fill(bmin, '0');
            Arrays.fill(bmax, '9');
            int j = 0;
            for (int i = 0; 2 * i < numLen; i++) {
                numorder[j++] = i;
                numorder[j++] = numLen - 1 - i;
            }
        }

        /**
         * Digit j of x now has minimum xmin[j]; any digit k of y that would
         * multiply with it to overshoot num[j+k] gets its max lowered.
         */
        void minChange(char[] xmin, int j, char[] ymax, int ylen, Deque<int[]> s) {
            char m = xmin[j];

            for (int k = 0; k < ylen && j + k < numLen; k++) {
                char nk = num.charAt(j + k);
                if (m > nk && ymax[k] > nk) {
                    s.push(new int[] {k, ymax[k]});
                    ymax[k] = nk;
                }
            }
        }

        static void unrollStack(Deque<int[]> s, int loc, char[] max) {
            while (s.size() > loc) {
                int[] e = s.pop();
                max[e[0]] = (char) e[1];
            }
        }

        int work(int depth) {
            int nSol = 0;
            int nCall = 0;

            if (depth >= numLen) {
                int rVal = spin(res, amin, amax, alen, reshash, 0, callback);
                if (rVal < 0) return rVal;
                int rVal2 = spin(res, bmin, bmax, blen, reshash, 0, callback);
                if (rVal2 < 0) return rVal2;
                return rVal + rVal2;
            }

            int i = numorder[depth];
            char ni = num.charAt(i);

            for (int j = (i >= alen ? i - alen + 1 : 0); j <= i && j < blen; j++) {
                int k = i - j;
                if (amax[k] < ni || bmax[j] < ni) continue;
                if (amin[k] <= ni) {
                    char omina = amin[k];
                    char omaxa = amax[k];
                    char ominb = bmin[j];
                    amin[k] = ni;
                    amax[k] = ni;
                    int aStackLoc = amaxstack.size();
                    int bStackLoc = bmaxstack.size();
                    minChange(amin, k, bmax, blen, bmaxstack);
                    if (bmin[j] < ni) {
                        bmin[j] = ni;
                        minChange(bmin, j, amax, alen, amaxstack);
                    }
                    nCall++;
                    int rVal = work(depth + 1);
                    if (rVal < 0) return rVal;
                    nSol += rVal;
                    unrollStack(amaxstack, aStackLoc, amax);
                    bmin[j] = ominb;
                    unrollStack(bmaxstack, bStackLoc, bmax);
                    amin[k] = omina;
                    amax[k] = omaxa;
                }
                if (bmin[j] <= ni) {
                    char ominb = bmin[j];
                    char omaxb = bmax[j];
                    char omina = amin[k];
                    bmin[j] = ni;
                    bmax[j] = ni;
                    int aStackLoc = amaxstack.size();
                    int bStackLoc = bmaxstack.size();
                    minChange(bmin, j, amax, alen, amaxstack);
                    if (amin[k] < ni) {
                        amin[k] = ni;
                        minChange(amin, k, bmax, blen, bmaxstack);
                    }
                    nCall++;
                    int rVal = work(depth + 1);
                    if (rVal < 0) return rVal;
                    nSol += rVal;
                    unrollStack(bmaxstack, bStackLoc, bmax);
                    amin[k] = omina;
                    unrollStack(amaxstack, aStackLoc, amax);
                    bmin[j] = ominb;
                    bmax[j] = omaxb;
                }
            }

            if (nCall == 0) nDeadEnd.increment();

            return nSol;
        }
    }

    /** Calls callback on every c such that den*c = num. */
    public static int dismalDivide(String num, String den, ToIntFunction<String> callback) {
        int numLen = num.length();
        int resLen = numLen + 1 - den.length();

        if (resLen <= 0) {
            System.err.printf("result length %d -> no solutions%n", resLen);
            return 0;
        }

        DivideSearch h = new DivideSearch(num, den, resLen, callback);
        int[] nMatch = new int[numLen];
        int[] nLoc = new int[numLen];

        Arrays.fill(h.amin, '0');
        Arrays.fill(h.amax, '9');
        for (int i = 0; i < numLen; i++) {
            h.numorder[i] = i;
            nMatch[i] = 0;
            nLoc[i] = i;
        }

        for (int i = 0; i < numLen; i++) {
            char ni = num.charAt(i);
            for (int j = (i >= resLen ? i - resLen + 1 : 0); j <= i && j < den.length(); j++) {
                if (den.charAt(j) > ni && h.amax[i - j] > ni) {
                    h.amax[i - j] = ni;
                }
            }
        }

        for (int i = 0; i < numLen; i++) {
            char ni = num.charAt(i);
            for (int j = (i >= resLen ? i - resLen + 1 : 0); j <= i && j < den.length(); j++) {
                if (den.charAt(j) >= ni && h.amax[i - j] >= ni) {
                    nMatch[i]++;
                }
            }
        }

        for (int i = 0; i < numLen; i++) {
            if (nMatch[i] == 0) return 0;
        }

        for (int i = numLen - 1; i >= 0; i--) {
            for (int j = 0; j < i; j++) {
                if (nMatch[j] > nMatch[j + 1]) {
                    int t = h.numorder[j]; h.numorder[j] = h.numorder[j + 1]; h.numorder[j + 1] = t;
                    t = nMatch[j]; nMatch[j] = nMatch[j + 1]; nMatch[j + 1] = t;
                }
            }
        }

        // As in the original: nLoc is the identity, so this resets numorder
        // to 0..numLen-1 and the sort above does not affect the search order.
        for (int i = 0; i < numLen; i++) {
            h.numorder[nLoc[i]] = i;
        }

        return h.work(0);
    }

    /** Calls callback on every b such that b*c = num for some c. */
    public static int dismalDivisors(String num, ToIntFunction<String> callback) {
        int numLen = num.length();
        DivisorSearch h = new DivisorSearch(num, callback, new HashSet<>());
        int nSol = 0;

        for (int i = 0; 2 * i < numLen; i++) {
            h.alen = i + 1;
            h.blen = numLen - i;
            int rVal = h.work(0);
            if (rVal < 0) return rVal;
            nSol += rVal;
        }

        return nSol;
    }

    public static int divPrint(String res) {
        return 0;
    }


    /** Divisor statistics for one number, accumulated by gatherInf. */
    private static final class DivInfo {
        final String num;
        final int len;
        boolean isPrime;
        boolean isPseudoprime = true;
        int nDivisors = 0;
        int nBoundedDivisors = 0;
        String dismalSumDivisors = "0";
        String dismalSumBoundedDivisors = "0";
        String dismalSumBoundedDivisors2 = "0";
        String dismalSumNeDivisors = "0";
        double sumDivisors = 0.0;
        double sumBoundedDivisors = 0.0;
        double sumBoundedDivisors2 = 0.0;
        double sumNeDivisors = 0.0;
        int nPrimeDivisors = 0;
        String dismalSumPrimeDivisors = "0";
        String dismalProdPrimeDivisors = "9";
        final Set<String> primeHash;

        DivInfo(String a, Set<String> primeHash) {
            this.num = a;
            this.len = a.length();
            this.isPrime = !(a.equals("8") || a.equals("9"));
            this.primeHash = primeHash;
        }

        int gatherInf(String res) {
            int resLen = res.length();
            int numLen = num.length();
            int numcmp = res.compareTo(num);
            double resf = res.isEmpty() ? 0.0 : Double.parseDouble(res);

            if (numcmp != 0 && !res.equals("9")) {
                isPrime = false;
            }
            if (resLen > 1 && resLen < numLen) isPseudoprime = false;
            nDivisors++;
            dismalSumDivisors = dismalAdd(res, dismalSumDivisors);
            sumDivisors += resf;
            if (resLen < numLen || numcmp <= 0) {
                nBoundedDivisors++;
                dismalSumBoundedDivisors = dismalAdd(res, dismalSumBoundedDivisors);
                sumBoundedDivisors += resf;
                if (resLen < numLen || numcmp < 0) {
                    dismalSumBoundedDivisors2 = dismalAdd(res, dismalSumBoundedDivisors2);
                    sumBoundedDivisors2 += resf;
                }
            }
            if (numcmp != 0) {
                dismalSumNeDivisors = dismalAdd(res, dismalSumNeDivisors);
                sumNeDivisors += resf;
            }

            if (primeHash.contains(res)) {
                nPrimeDivisors++;
                dismalSumPrimeDivisors = dismalAdd(res, dismalSumPrimeDivisors);
                if (resLen + dismalProdPrimeDivisors.length() <= DIV_PROD_MUL * numLen) {
                    dismalProdPrimeDivisors = dismalMul(res, dismalProdPrimeDivisors);
                } else {
                    dismalProdPrimeDivisors = "9".repeat(DIV_PROD_MUL * numLen);
                }
            }

            return 0;
        }

        /**
         * Adds the divisors gathered in other (same num, disjoint divisors) to
         * this one. Every field combines regardless of order: dismal + and *
         * are associative and commutative, and the capped product is capped
         * exactly when the full product would be.
         */
        DivInfo merge(DivInfo other) {
            isPrime &= other.isPrime;
            isPseudoprime &= other.isPseudoprime;
            nDivisors += other.nDivisors;
            nBoundedDivisors += other.nBoundedDivisors;
            dismalSumDivisors = dismalAdd(dismalSumDivisors, other.dismalSumDivisors);
            dismalSumBoundedDivisors = dismalAdd(dismalSumBoundedDivisors, other.dismalSumBoundedDivisors);
            dismalSumBoundedDivisors2 = dismalAdd(dismalSumBoundedDivisors2, other.dismalSumBoundedDivisors2);
            dismalSumNeDivisors = dismalAdd(dismalSumNeDivisors, other.dismalSumNeDivisors);
            sumDivisors += other.sumDivisors;
            sumBoundedDivisors += other.sumBoundedDivisors;
            sumBoundedDivisors2 += other.sumBoundedDivisors2;
            sumNeDivisors += other.sumNeDivisors;
            nPrimeDivisors += other.nPrimeDivisors;
            dismalSumPrimeDivisors = dismalAdd(dismalSumPrimeDivisors, other.dismalSumPrimeDivisors);
            int cap = DIV_PROD_MUL * len;
            if (dismalProdPrimeDivisors.length() + other.dismalProdPrimeDivisors.length() <= cap) {
                dismalProdPrimeDivisors = dismalMul(dismalProdPrimeDivisors, other.dismalProdPrimeDivisors);
            } else {
                dismalProdPrimeDivisors = "9".repeat(cap);
            }
            return this;
        }
    }

    /**
     * Gathers the divisor info of num, searching each split of num into
     * factor lengths (i+1, numLen-i) in parallel and merging the results.
     */
    private static DivInfo divisorInfo(String num, Set<String> primeHash) {
        int numLen = num.length();
        Set<String> reshash = ConcurrentHashMap.newKeySet();
        return IntStream.range(0, (numLen + 1) / 2)
                .parallel()
                .mapToObj(i -> {
                    DivInfo part = new DivInfo(num, primeHash);
                    DivisorSearch h = new DivisorSearch(num, part::gatherInf, reshash);
                    h.alen = i + 1;
                    h.blen = numLen - i;
                    h.work(0);
                    return part;
                })
                .reduce(DivInfo::merge)
                .orElseGet(() -> new DivInfo(num, primeHash));
    }

    /** Callback for dismalDivisors: 1 for a divisor of num other than num and 9. */
    private static int properDivisor(String res, String num) {
        if (res.equals(num) || res.equals("9")) {
            return 0;
        } else {
            return 1;
        }
    }

    private static boolean isDismalPrime(String x) {
        // If the largest digit d of x is below 9 then d*x = x, so d is a proper
        // divisor: every prime contains a 9 (this also rules out 1..8).
        if (x.indexOf('9') < 0 || x.equals("9")) return false;
        // Stop the search at the first proper divisor.
        return dismalDivisors(x, res -> properDivisor(res, x) > 0 ? -1 : 0) == 0;
    }

    /** Returns n+1 in ordinary decimal arithmetic. */
    public static String incrDigitNum(String n) {
        char[] c = n.toCharArray();
        int i = c.length - 1;

        while (i >= 0) {
            if (c[i] != '9') {
                c[i]++;
                return new String(c);
            } else {
                c[i] = '0';
                i--;
            }
        }

        return "1" + new String(c);
    }



    /** Every dismal prime with at most primeCacheLen digits, kept across calls. */
    private static final Set<String> primeCache = new HashSet<>();
    private static int primeCacheLen = 0;

    /**
     * Returns the set of all dismal primes with at most maxLen digits, testing
     * each new digit length in parallel (maxLen at most 18).
     */
    private static synchronized Set<String> primesUpToLength(int maxLen) {
        while (primeCacheLen < maxLen) {
            int len = primeCacheLen + 1;
            String lo = len == 1 ? "1" : "1" + "0".repeat(len - 1);
            primeCache.addAll(Arrays.asList(pPrimesRange(lo, "9".repeat(len))));
            primeCacheLen = len;
        }
        return primeCache;
    }

    /** Formats like C's printf("%.0f"): the exact integer value of d. */
    private static String fmt0(double d) {
        return new BigDecimal(d).setScale(0, java.math.RoundingMode.HALF_EVEN).toPlainString();
    }

    /**
     * Returns the dinfo/pdinfo table for lo <= n <= hi: row 0 is the header,
     * then one row per n (the column names are listed in README.md).
     */
    public static String[][] dinfoTable(String lo, String hi, boolean primefields) {
        // Divisors of n never have more digits than n, so primes longer than
        // hi in the shared cache can never match.
        Set<String> primeHash = primefields ? primesUpToLength(hi.length()) : Set.of();

        List<String[]> rows = new ArrayList<>();
        String header =
                "n|9ish|prime|pseudoprime|divisors|bd_divisors|dsum_divisors|dsum_bd_divisors|dsum_bd_divisors2|dsum_ne_divisors|2*n|sum_divisors|sum_bd_divisors|sum_bd_divisors2|sum_ne_divisors";
        if (primefields) header += "|prime_divisors|sum_prime_divisors|prod_prime_divisors";
        rows.add(header.split("\\|"));

        LongStream.rangeClosed(Long.parseLong(lo), Long.parseLong(hi))
                .parallel()
                .mapToObj(n -> dinfoRow(Long.toString(n), primeHash, primefields))
                .forEachOrdered(rows::add);
        return rows.toArray(new String[0][]);
    }

    /** One dinfoTable row for x. */
    private static String[] dinfoRow(String x, Set<String> primeHash, boolean primefields) {
        DivInfo di = divisorInfo(x, primeHash);
        String x2 = dismalMul(x, "2");

        List<String> row = new ArrayList<>(Arrays.asList(
                x,
                x.indexOf('9') >= 0 ? "1" : "0",
                di.isPrime ? "1" : "0",
                di.isPseudoprime ? "1" : "0",
                String.valueOf(di.nDivisors),
                String.valueOf(di.nBoundedDivisors),
                di.dismalSumDivisors,
                di.dismalSumBoundedDivisors,
                di.dismalSumBoundedDivisors2,
                di.dismalSumNeDivisors,
                x2,
                fmt0(di.sumDivisors),
                fmt0(di.sumBoundedDivisors),
                fmt0(di.sumBoundedDivisors2),
                fmt0(di.sumNeDivisors)));
        if (primefields) {
            row.add(String.valueOf(di.nPrimeDivisors));
            row.add(di.dismalSumPrimeDivisors);
            row.add(di.dismalProdPrimeDivisors);
        }
        return row.toArray(new String[0]);
    }

    /** Divisor info for lo <= n <= hi, as a table (C command: dinfo). */
    public static String[][] dinfo(String lo, String hi) {
        return dinfoTable(lo, hi, false);
    }

    /** Divisor and prime-divisor info for lo <= n <= hi, as a table (C command: pdinfo). */
    public static String[][] pdinfo(String lo, String hi) {
        return dinfoTable(lo, hi, true);
    }

    /** Prints the dinfoTable as '|' separated lines, like the C program. */
    public static void dinfoRange(String lo, String hi, boolean primefields) {
        for (String[] row : dinfoTable(lo, hi, primefields)) {
            System.out.println(String.join("|", row));
        }
    }

    /**
     * Counts the dismal primes in [lo,hi], testing the numbers in parallel.
     * lo and hi must fit in a long (at most 18 digits).
     */
    public static int pCountRange(String lo, String hi) {
        return (int) LongStream.rangeClosed(Long.parseLong(lo), Long.parseLong(hi))
                .parallel()
                .mapToObj(Long::toString)
                .filter(CarrylessArithmetic::isDismalPrime)
                .count();
    }

    /**
     * Returns the dismal primes in [lo,hi] in increasing order, testing the
     * numbers in parallel. lo and hi must fit in a long (at most 18 digits).
     */
    public static String[] pPrimesRange(String lo, String hi) {
        return LongStream.rangeClosed(Long.parseLong(lo), Long.parseLong(hi))
                .parallel()
                .mapToObj(Long::toString)
                .filter(CarrylessArithmetic::isDismalPrime)
                .toArray(String[]::new);
    }
}
