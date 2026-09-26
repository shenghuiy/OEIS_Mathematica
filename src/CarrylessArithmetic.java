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
   pcountRange(a, b)        Counts the primes in [a,b]
   dinfoRange(a, b, false)  Outputs info about divisors of n, a<=n<=b
   dinfoRange(a, b, true)   Outputs info about prime divisors of n, a<=n<=b
   helpDinfo()              Describes the output of dinfoRange

The callback passed to dismalDivide / dismalDivisors receives each result
once and returns an int; the returned ints are summed and handed back to
the caller.  A negative return value aborts the search.

**************************************************************************
                                           */

import java.math.BigDecimal;
import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Deque;
import java.util.HashSet;
import java.util.Set;
import java.util.function.ToIntFunction;

public final class CarrylessArithmetic {

  private CarrylessArithmetic() {}

  static int nfound = 0;
  static int ndeadend = 0;
  static int ndup = 0;

  static final int DIV_PROD_MUL = 16;

  public static String dismalMul(String a, String b) {
    int reslen = a.length() + b.length() - 1;
    char[] res = new char[reslen];
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
    int nsol = 0;

    if (depth >= len) {
      int start = 0;
      while (start < len && res[start] == '0') start++;
      String s = new String(res, start, len - start);
      if (reshash.add(s)) {
        nfound++;
        nsol = callback.applyAsInt(s);
        return nsol;
      } else {
        ndup++;
        return 0;
      }
    }

    for (char d = min[depth]; d <= max[depth]; d++) {
      res[depth] = d;
      nsol += spin(res, min, max, len, reshash, depth + 1, callback);
    }
    return nsol;
  }

  /** Search state for dismalDivide: the quotient digit ranges and results. */
  private static final class DivideSearch {
    final String num;
    final String den;
    final int numlen;
    final int alen;
    final char[] amin;
    final char[] amax;
    final int[] numorder;
    final char[] res;
    final Set<String> reshash = new HashSet<>();
    final ToIntFunction<String> callback;

    DivideSearch(String num, String den, int reslen, ToIntFunction<String> callback) {
      this.num = num;
      this.den = den;
      this.numlen = num.length();
      this.alen = reslen;
      this.amin = new char[reslen];
      this.amax = new char[reslen];
      this.numorder = new int[numlen];
      this.res = new char[reslen];
      this.callback = callback;
    }

    int work(int depth) {
      int nsol = 0;
      int ncall = 0;

      if (depth >= numlen) {
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
          ncall++;
          int rval = work(depth + 1);
          if (rval < 0) return rval;
          nsol += rval;
          amin[k] = omin;
          amax[k] = omax;
        } else if (dj == ni && amax[k] >= ni) {
          char omin = amin[k];
          if (omin < ni) amin[k] = ni;
          ncall++;
          int rval = work(depth + 1);
          if (rval < 0) return rval;
          nsol += rval;
          amin[k] = omin;
        }
      }

      if (ncall == 0) ndeadend++;
      return nsol;
    }
  }

  /** Search state for dismalDivisors: digit ranges of both factors a and b. */
  private static final class DivisorSearch {
    final String num;
    final int numlen;
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
    final Set<String> reshash = new HashSet<>();
    final ToIntFunction<String> callback;

    DivisorSearch(String num, ToIntFunction<String> callback) {
      this.num = num;
      this.numlen = num.length();
      this.amin = new char[numlen];
      this.amax = new char[numlen];
      this.bmin = new char[numlen];
      this.bmax = new char[numlen];
      this.numorder = new int[numlen + 1];
      this.res = new char[numlen];
      this.callback = callback;
    }

    /**
     * Digit j of x now has minimum xmin[j]; any digit k of y that would
     * multiply with it to overshoot num[j+k] gets its max lowered.
     */
    void minChange(char[] xmin, int j, char[] ymax, int ylen, Deque<int[]> s) {
      char m = xmin[j];

      for (int k = 0; k < ylen && j + k < numlen; k++) {
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
      int nsol = 0;
      int ncall = 0;

      if (depth >= numlen) {
        int rval = spin(res, amin, amax, alen, reshash, 0, callback);
        if (rval < 0) return rval;
        int rval2 = spin(res, bmin, bmax, blen, reshash, 0, callback);
        if (rval2 < 0) return rval2;
        return rval + rval2;
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
          int astackloc = amaxstack.size();
          int bstackloc = bmaxstack.size();
          minChange(amin, k, bmax, blen, bmaxstack);
          if (bmin[j] < ni) {
            bmin[j] = ni;
            minChange(bmin, j, amax, alen, amaxstack);
          }
          ncall++;
          int rval = work(depth + 1);
          if (rval < 0) return rval;
          nsol += rval;
          unrollStack(amaxstack, astackloc, amax);
          bmin[j] = ominb;
          unrollStack(bmaxstack, bstackloc, bmax);
          amin[k] = omina;
          amax[k] = omaxa;
        }
        if (bmin[j] <= ni) {
          char ominb = bmin[j];
          char omaxb = bmax[j];
          char omina = amin[k];
          bmin[j] = ni;
          bmax[j] = ni;
          int astackloc = amaxstack.size();
          int bstackloc = bmaxstack.size();
          minChange(bmin, j, amax, alen, amaxstack);
          if (amin[k] < ni) {
            amin[k] = ni;
            minChange(amin, k, bmax, blen, bmaxstack);
          }
          ncall++;
          int rval = work(depth + 1);
          if (rval < 0) return rval;
          nsol += rval;
          unrollStack(bmaxstack, bstackloc, bmax);
          amin[k] = omina;
          unrollStack(amaxstack, astackloc, amax);
          bmin[j] = ominb;
          bmax[j] = omaxb;
        }
      }

      if (ncall == 0) ndeadend++;

      return nsol;
    }
  }

  /** Calls callback on every c such that den*c = num. */
  public static int dismalDivide(String num, String den, ToIntFunction<String> callback) {
    int numlen = num.length();
    int reslen = numlen + 1 - den.length();

    if (reslen <= 0) {
      System.err.printf("result length %d -> no solutions%n", reslen);
      return 0;
    }

    DivideSearch h = new DivideSearch(num, den, reslen, callback);
    int[] nmatch = new int[numlen];
    int[] nloc = new int[numlen];

    Arrays.fill(h.amin, '0');
    Arrays.fill(h.amax, '9');
    for (int i = 0; i < numlen; i++) {
      h.numorder[i] = i;
      nmatch[i] = 0;
      nloc[i] = i;
    }

    for (int i = 0; i < numlen; i++) {
      char ni = num.charAt(i);
      for (int j = (i >= reslen ? i - reslen + 1 : 0); j <= i && j < den.length(); j++) {
        if (den.charAt(j) > ni && h.amax[i - j] > ni) {
          h.amax[i - j] = ni;
        }
      }
    }

    for (int i = 0; i < numlen; i++) {
      char ni = num.charAt(i);
      for (int j = (i >= reslen ? i - reslen + 1 : 0); j <= i && j < den.length(); j++) {
        if (den.charAt(j) >= ni && h.amax[i - j] >= ni) {
          nmatch[i]++;
        }
      }
    }

    for (int i = 0; i < numlen; i++) {
      if (nmatch[i] == 0) return 0;
    }

    for (int i = numlen - 1; i >= 0; i--) {
      for (int j = 0; j < i; j++) {
        if (nmatch[j] > nmatch[j + 1]) {
          int t = h.numorder[j]; h.numorder[j] = h.numorder[j + 1]; h.numorder[j + 1] = t;
          t = nmatch[j]; nmatch[j] = nmatch[j + 1]; nmatch[j + 1] = t;
        }
      }
    }

    // As in the original: nloc is the identity, so this resets numorder
    // to 0..numlen-1 and the sort above does not affect the search order.
    for (int i = 0; i < numlen; i++) {
      h.numorder[nloc[i]] = i;
    }

    return h.work(0);
  }

  /** Calls callback on every b such that b*c = num for some c. */
  public static int dismalDivisors(String num, ToIntFunction<String> callback) {
    int numlen = num.length();
    DivisorSearch h = new DivisorSearch(num, callback);
    int nsol = 0;

    Arrays.fill(h.amin, '0');
    Arrays.fill(h.amax, '9');
    Arrays.fill(h.bmin, '0');
    Arrays.fill(h.bmax, '9');
    int j = 0;
    for (int i = 0; 2 * i < numlen; i++) {
      h.numorder[j++] = i;
      h.numorder[j++] = numlen - 1 - i;
    }

    for (int i = 0; 2 * i < numlen; i++) {
      h.alen = i + 1;
      h.blen = numlen - i;
      int rval = h.work(0);
      if (rval < 0) return rval;
      nsol += rval;
    }

    return nsol;
  }

  public static int divPrint(String res) {
    System.out.println(res);
    return 0;
  }

  public static void usage(String fname) {
    System.err.printf("Usage: %s cmd [args...]%n", fname);
    System.err.println("available cmds are:");
    System.err.println("   div a b           Outputs c such that b*c = a");
    System.err.println("   divs a            Outputs b such that b*c = a for some c");
    System.err.println("   add a b           Outputs a+b");
    System.err.println("   mul a b           Outputs a*b");
    System.err.println("   pcount a b        Counts the primes in [a,b]");
    System.err.println("   dinfo a           Outputs info about divisors of a");
    System.err.println("   dinfo a b         Outputs info about divisors of n, a<=n<=b");
    System.err.println("   pdinfo a          Outputs info about prime divisors of a");
    System.err.println("   pdinfo a b        Outputs info about prime divisors of n, a<=n<=b");
    System.err.println("   help_dinfo        Describes the output of dinfo and pdinfo");
    System.err.println("   help              Outputs this text");
  }

  /** Divisor statistics for one number, accumulated by gatherInf. */
  private static final class DivInfo {
    final String num;
    final int len;
    boolean isPrime;
    boolean isPseudoprime = true;
    int ndivisors = 0;
    int nboundedDivisors = 0;
    String dismalSumDivisors = "0";
    String dismalSumBoundedDivisors = "0";
    String dismalSumBoundedDivisors2 = "0";
    String dismalSumNeDivisors = "0";
    double sumDivisors = 0.0;
    double sumBoundedDivisors = 0.0;
    double sumBoundedDivisors2 = 0.0;
    double sumNeDivisors = 0.0;
    int nprimeDivisors = 0;
    String dismalSumPrimeDivisors = "0";
    String dismalProdPrimeDivisors = "9";
    final Set<String> primehash;

    DivInfo(String a, Set<String> primehash) {
      this.num = a;
      this.len = a.length();
      this.isPrime = !(a.equals("8") || a.equals("9"));
      this.primehash = primehash;
    }

    int gatherInf(String res) {
      int reslen = res.length();
      int numlen = num.length();
      int numcmp = res.compareTo(num);
      double resf = res.isEmpty() ? 0.0 : Double.parseDouble(res);

      if (numcmp != 0 && !res.equals("9")) {
        isPrime = false;
      }
      if (reslen > 1 && reslen < numlen) isPseudoprime = false;
      ndivisors++;
      dismalSumDivisors = dismalAdd(res, dismalSumDivisors);
      sumDivisors += resf;
      if (reslen < numlen || numcmp <= 0) {
        nboundedDivisors++;
        dismalSumBoundedDivisors = dismalAdd(res, dismalSumBoundedDivisors);
        sumBoundedDivisors += resf;
        if (reslen < numlen || numcmp < 0) {
          dismalSumBoundedDivisors2 = dismalAdd(res, dismalSumBoundedDivisors2);
          sumBoundedDivisors2 += resf;
        }
      }
      if (numcmp != 0) {
        dismalSumNeDivisors = dismalAdd(res, dismalSumNeDivisors);
        sumNeDivisors += resf;
      }

      if (primehash.contains(res)) {
        nprimeDivisors++;
        dismalSumPrimeDivisors = dismalAdd(res, dismalSumPrimeDivisors);
        if (reslen + dismalProdPrimeDivisors.length() <= DIV_PROD_MUL * numlen) {
          dismalProdPrimeDivisors = dismalMul(res, dismalProdPrimeDivisors);
        } else {
          dismalProdPrimeDivisors = "9".repeat(DIV_PROD_MUL * numlen);
        }
      }

      return 0;
    }
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
    return !x.equals("8") && !x.equals("9")
        && dismalDivisors(x, res -> properDivisor(res, x)) == 0;
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

  public static void helpDinfo() {
    System.out.println("dinfo and pdinfo output a header row, and then a row for each");
    System.out.println("number requested.  Each row consists of '|' separated fields.");
    System.out.println();
    System.out.println("The fields are:");
    System.out.println("  n                   the number");
    System.out.println("  9ish                1 if n contains a 9, 0 otherwise");
    System.out.println("  prime               1 if n is prime, 0 otherwise");
    System.out.println("                         n is prime if n != 9, and if n=a*b, ");
    System.out.println("                         then either a==9 or b==9");
    System.out.println("  pseudoprime         1 if n has a divisor with length in [2,n)");
    System.out.println("  divisors            the number of divisors of n");
    System.out.println("  bd_divisors         the number of divisors of n in [1,n]");
    System.out.println("  dsum_divisors       the dismal sum of the divisors of n");
    System.out.println("  dsum_bd_divisors    the dismal sum of the divisors of n in [1,n]");
    System.out.println("  dsum_bd_divisors2   the dismal sum of the divisors of n in [1,n)");
    System.out.println("  dsum_ne_divisors    the dismal sum of the divisors of n that are != n");
    System.out.println("  2*n                 the dismal product 2*n");
    System.out.println("  sum_divisors        the normal sum of the divisors of n");
    System.out.println("  sum_bd_divisors     the normal sum of the divisors of n in [1,n]");
    System.out.println("  sum_bd_divisors2    the normal sum of the divisors of n in [1,n)");
    System.out.println("  sum_ne_divisors     the normal sum of the divisors of n that are != n");
    System.out.println();
    System.out.println("In addition, pdinfo includes the following fields about prime divisors");
    System.out.println("  prime_divisors      the number of prime divisors of n");
    System.out.println("  sum_prime_divisors  the dismal sum of the prime divisors of n");
    System.out.println("  prod_prime_divisors the dismal product of the prime divisors of n");
    System.out.println("                        because numbers like 111...111 have very many");
    System.out.println("                        prime divisors, this product is capped at");
    System.out.printf("                        length %d*length(n)%n", DIV_PROD_MUL);
  }

  /** Adds every dismal prime with at most length(hi) digits to primehash. */
  private static void collectPrimes(Set<String> primehash, String hi) {
    int hilen = hi.length();
    String x = "1";

    while (x.length() <= hilen) {
      if (isDismalPrime(x)) {
        primehash.add(x);
      }
      x = incrDigitNum(x);
    }
  }

  /** True if x <= hi as decimal numbers (both without leading zeros). */
  private static boolean notPast(String x, String hi) {
    return x.length() < hi.length()
        || (x.length() == hi.length() && x.compareTo(hi) <= 0);
  }

  /** Formats like C's printf("%.0f"): the exact integer value of d. */
  private static String fmt0(double d) {
    return new BigDecimal(d).setScale(0, java.math.RoundingMode.HALF_EVEN).toPlainString();
  }

  public static void dinfoRange(String lo, String hi, boolean primefields) {
    Set<String> primehash = new HashSet<>();

    if (primefields) {
      collectPrimes(primehash, hi);
    }

    String x = lo;

    StringBuilder header = new StringBuilder(
        "n|9ish|prime|pseudoprime|divisors|bd_divisors|dsum_divisors|dsum_bd_divisors|dsum_bd_divisors2|dsum_ne_divisors|2*n|sum_divisors|sum_bd_divisors|sum_bd_divisors2|sum_ne_divisors");
    if (primefields) header.append("|prime_divisors|sum_prime_divisors|prod_prime_divisors");
    System.out.println(header);

    while (notPast(x, hi)) {
      DivInfo di = new DivInfo(x, primehash);

      dismalDivisors(x, di::gatherInf);
      String x2 = dismalMul(x, "2");

      StringBuilder line = new StringBuilder();
      line.append(x).append('|')
          .append(x.indexOf('9') >= 0 ? 1 : 0).append('|')
          .append(di.isPrime ? 1 : 0).append('|')
          .append(di.isPseudoprime ? 1 : 0).append('|')
          .append(di.ndivisors).append('|')
          .append(di.nboundedDivisors).append('|')
          .append(di.dismalSumDivisors).append('|')
          .append(di.dismalSumBoundedDivisors).append('|')
          .append(di.dismalSumBoundedDivisors2).append('|')
          .append(di.dismalSumNeDivisors).append('|')
          .append(x2).append('|')
          .append(fmt0(di.sumDivisors)).append('|')
          .append(fmt0(di.sumBoundedDivisors)).append('|')
          .append(fmt0(di.sumBoundedDivisors2)).append('|')
          .append(fmt0(di.sumNeDivisors));
      if (primefields) {
        line.append('|').append(di.nprimeDivisors)
            .append('|').append(di.dismalSumPrimeDivisors)
            .append('|').append(di.dismalProdPrimeDivisors);
      }
      System.out.println(line);

      x = incrDigitNum(x);
    }
  }

  public static void pcountRange(String lo, String hi) {
    String x = lo;
    int pcount = 0;
    int outputLength = lo.length();

    while (notPast(x, hi)) {
      if (isDismalPrime(x)) {
        pcount++;
      }
      x = incrDigitNum(x);
      if (x.length() > outputLength) {
        System.out.printf("%d primes with <= %d digits%n", pcount, outputLength);
        System.out.flush();
        outputLength++;
      }
    }
    System.out.printf("%d primes in [%s,%s]%n", pcount, lo, hi);
  }
}
