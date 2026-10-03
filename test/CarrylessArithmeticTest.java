import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * Tests for CarrylessArithmetic. The files in test/expected are the output of
 * the original C program (David Applegate, 2003) for the same inputs, so these
 * tests check the Java port against the reference implementation.
 */
class CarrylessArithmeticTest {

    private static List<String> expected(String file) throws IOException {
        return Files.readAllLines(Path.of("test", "expected", file));
    }

    private static List<String> lines(String[][] table) {
        return Arrays.stream(table).map(row -> String.join("|", row)).collect(Collectors.toList());
    }

    private static List<String> divisors(String num) {
        List<String> out = new ArrayList<>();
        CarrylessArithmetic.dismalDivisors(num, d -> { out.add(d); return 0; });
        return out;
    }

    private static List<String> quotients(String num, String den) {
        List<String> out = new ArrayList<>();
        CarrylessArithmetic.dismalDivide(num, den, c -> { out.add(c); return 0; });
        return out;
    }

    // ---- addition and multiplication ----

    @ParameterizedTest(name = "{0} + {1} = {2}")
    @CsvSource({"123, 4567, 4567", "9, 1, 9", "1906, 7, 1907"})
    @DisplayName("dismalAdd matches the C program")
    void add(String a, String b, String sum) {
        assertEquals(sum, CarrylessArithmetic.dismalAdd(a, b));
        assertEquals(sum, CarrylessArithmetic.dismalAdd(b, a));
    }

    @ParameterizedTest(name = "{0} * {1} = {2}")
    @CsvSource({"17, 24, 124", "123, 456, 12333", "9, 90, 90", "12, 57, 122", "1906, 2, 1202"})
    @DisplayName("dismalMul matches the C program")
    void mul(String a, String b, String product) {
        assertEquals(product, CarrylessArithmetic.dismalMul(a, b));
        assertEquals(product, CarrylessArithmetic.dismalMul(b, a));
    }

    @ParameterizedTest(name = "{0} + 1 = {1}")
    @CsvSource({"1, 2", "9, 10", "1999, 2000", "123, 124"})
    @DisplayName("incrDigitNum adds 1 in ordinary decimal")
    void increment(String n, String next) {
        assertEquals(next, CarrylessArithmetic.incrDigitNum(n));
    }

    // ---- divisors and division ----

    @ParameterizedTest(name = "divisors of {0}")
    @CsvSource({"10", "1111", "1234", "98765"})
    @DisplayName("dismalDivisors gives the C program's divisors, in the same order")
    void divisorsMatchC(String num) throws IOException {
        assertEquals(expected("divs_" + num + ".txt"), divisors(num));
    }

    @ParameterizedTest(name = "{0} / {1}")
    @CsvSource({"11111, 11", "122, 12", "999, 9"})
    @DisplayName("dismalDivide gives the C program's quotients, in the same order")
    void divideMatchesC(String num, String den) throws IOException {
        assertEquals(expected("div_" + num + "_" + den + ".txt"), quotients(num, den));
    }

    @ParameterizedTest(name = "{1} * c = {0} for every quotient c")
    @CsvSource({"11111, 11", "122, 12", "999, 9"})
    @DisplayName("every quotient multiplies back to the dividend")
    void quotientsMultiplyBack(String num, String den) {
        List<String> qs = quotients(num, den);
        assertTrue(!qs.isEmpty());
        for (String c : qs) {
            assertEquals(num, CarrylessArithmetic.dismalMul(den, c), "quotient " + c);
        }
    }

    @ParameterizedTest(name = "{0} / {1} has no solution")
    @CsvSource({"1234, 12", "1234, 56", "12, 1234"})
    @DisplayName("divisions with no solution report none")
    void noSolution(String num, String den) {
        assertEquals(0, CarrylessArithmetic.dismalDivide(num, den, c -> 1));
    }

    @Test
    @DisplayName("a negative callback result stops the search at once")
    void negativeCallbackAborts() {
        int[] calls = {0};
        int r = CarrylessArithmetic.dismalDivide("11111", "11", c -> { calls[0]++; return -1; });
        assertEquals(-1, r);
        assertEquals(1, calls[0]);
    }

    // ---- dinfo / pdinfo ----

    @Test
    @DisplayName("dinfo 1..300 matches the C program")
    void dinfoMatchesC() throws IOException {
        assertEquals(expected("dinfo_1_300.txt"), lines(CarrylessArithmetic.dinfo("1", "300")));
    }

    @ParameterizedTest(name = "pdinfo {0}..{1}")
    @CsvSource({"1, 2000, pdinfo_1_2000.txt", "11111, 11111, pdinfo_11111.txt",
            "99990, 100010, pdinfo_99990_100010.txt"})
    @DisplayName("pdinfo matches the C program")
    void pdinfoMatchesC(String lo, String hi, String file) throws IOException {
        assertEquals(expected(file), lines(CarrylessArithmetic.pdinfo(lo, hi)));
    }

    @Test
    @DisplayName("an empty pdinfo range gives only the header row")
    void pdinfoEmptyRange() {
        assertEquals(1, CarrylessArithmetic.pdinfo("50", "10").length);
    }

    // ---- primes ----

    @ParameterizedTest(name = "{2} primes in [{0},{1}]")
    @CsvSource({"1, 20000, 2291", "100, 199, 1", "123456, 234567, 12583", "1, 99999, 22095", "50, 10, 0"})
    @DisplayName("pCountRange matches the C program's pcount")
    void countMatchesC(String lo, String hi, int count) {
        assertEquals(count, CarrylessArithmetic.pCountRange(lo, hi));
    }

    @Test
    @DisplayName("pPrimesRange starts like OEIS A087097")
    void firstPrimes() {
        String[] first = Arrays.copyOf(CarrylessArithmetic.pPrimesRange("1", "199"), 19);
        assertArrayEquals(new String[] {"19", "29", "39", "49", "59", "69", "79", "89", "90", "91",
                "92", "93", "94", "95", "96", "97", "98", "99", "109"}, first);
    }

    @Test
    @DisplayName("pPrimesRange is increasing, agrees with pCountRange, and every prime contains a 9")
    void primesConsistent() {
        String[] primes = CarrylessArithmetic.pPrimesRange("1", "99999");
        assertEquals(CarrylessArithmetic.pCountRange("1", "99999"), primes.length);
        for (int i = 0; i < primes.length; i++) {
            assertTrue(primes[i].indexOf('9') >= 0, primes[i]);
            if (i > 0) assertTrue(Long.parseLong(primes[i - 1]) < Long.parseLong(primes[i]));
        }
    }

    @Test
    @DisplayName("an empty pPrimesRange range gives no primes")
    void primesEmptyRange() {
        assertEquals(0, CarrylessArithmetic.pPrimesRange("50", "10").length);
    }
}
