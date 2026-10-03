# OEIS_Mathematica
High-performance Wolfram Language code for computing a difficult OEIS sequence — too long for the OEIS program section

## Java: carry-less (dismal) arithmetic

`src/CarrylessArithmetic.java` is a Java port of David Applegate's C program for dismal arithmetic (2003), now usually called lunar or carry-less arithmetic. Adding two numbers takes the larger digit in each position, and multiplying takes the smaller ([A087061](https://oeis.org/A087061), [A087062](https://oeis.org/A087062)); the primes are [A087097](https://oeis.org/A087097).

All numbers are passed and returned as decimal digit strings, such as `"1906"`.

### Build

Requires Java 11 or later and Maven.

```bash
mvn package    # compiles, runs the tests, builds target/carryless-arithmetic-1.0-SNAPSHOT.jar
mvn test       # tests only
```

### Methods

All methods are `public static`.

| Method | Returns |
|---|---|
| `dismalAdd(a, b)` | `a + b` |
| `dismalMul(a, b)` | `a × b` |
| `dismalDivide(num, den, callback)` | Calls `callback` once for every `c` with `den × c = num`; returns the sum of the callback's return values |
| `dismalDivisors(num, callback)` | Calls `callback` once for every divisor of `num`; returns the sum of the callback's return values |
| `pCountRange(lo, hi)` | The number of primes in `[lo, hi]` |
| `pPrimesRange(lo, hi)` | The primes in `[lo, hi]`, in increasing order, as a `String[]` |
| `dinfo(lo, hi)` | A `String[][]` table of divisor information for each `n` in `[lo, hi]`; row 0 holds the column names |
| `pdinfo(lo, hi)` | The same table with three prime-divisor columns added |
| `dinfoRange(lo, hi, primefields)` | Prints the `dinfo` (`false`) or `pdinfo` (`true`) table as `\|`-separated lines, like the C program |
| `incrDigitNum(n)` | `n + 1` in ordinary decimal |

A callback is a `ToIntFunction<String>`. Return `0` to keep going, or a negative value to stop the search at once.

Division is not unique: `12 × c = 122` has 64 solutions, from `22` to `99`, including `57`.

### Example (Java)

```java
CarrylessArithmetic.dismalMul("12", "57");          // "122"
CarrylessArithmetic.pCountRange("1", "20000");      // 2291
CarrylessArithmetic.pPrimesRange("100", "199");     // ["109"]

List<String> qs = new ArrayList<>();
CarrylessArithmetic.dismalDivide("122", "12", c -> { qs.add(c); return 0; });   // qs has 64 entries
```

### Example (Mathematica, via J/Link)

```wolfram
Needs["JLink`"];
ReinstallJava[];   (* also after rebuilding the jar, so the new class is loaded *)
AddToClassPath["/path/to/target/carryless-arithmetic-1.0-SNAPSHOT.jar"];
LoadJavaClass["CarrylessArithmetic"];

CarrylessArithmetic`dismalMul["12", "57"]          (* "122" *)
CarrylessArithmetic`pCountRange["1", "20000"]      (* 2291 *)
ps = CarrylessArithmetic`pPrimesRange["1", "999"]; (* a list of 99 strings *)

t = CarrylessArithmetic`pdinfo["98", "101"];
TableForm[Rest[t], TableHeadings -> {None, First[t]}]
```

Methods that return a value convert directly to Wolfram expressions. To pass a callback, create one with `ImplementJavaInterface["java.util.function.ToIntFunction", {"applyAsInt" -> "f"}]` and wrap the call in `JavaBlock` so the callback object is released afterwards. Each callback is a round trip between Java and the kernel, so for large results the array-returning methods are much faster.

### Table columns

`dinfo` has 15 columns:

| Column | Meaning |
|---|---|
| `n` | The number |
| `9ish` | 1 if `n` contains a 9 |
| `prime` | 1 if `n` is not 8 or 9 and its only divisors are 9 and `n` itself |
| `pseudoprime` | 1 if `n` has no divisor with between 2 and `length(n) − 1` digits |
| `divisors`, `bd_divisors` | The number of divisors of `n`, and of those in `[1, n]` |
| `dsum_divisors`, `dsum_bd_divisors`, `dsum_bd_divisors2`, `dsum_ne_divisors` | Dismal sums of the divisors: all, those in `[1, n]`, those in `[1, n)`, and those `≠ n` |
| `2*n` | The dismal product `2 × n` |
| `sum_divisors`, `sum_bd_divisors`, `sum_bd_divisors2`, `sum_ne_divisors` | Ordinary sums of the same four sets |

`pdinfo` adds `prime_divisors` (how many divisors are prime), `sum_prime_divisors` (their dismal sum) and `prod_prime_divisors` (their dismal product, capped at 16 × `length(n)` digits of 9).

### Performance

`pCountRange`, `pPrimesRange`, `dinfo` and `pdinfo` use every CPU core, and for these methods `lo` and `hi` must have at most 18 digits. `pdinfo` keeps the primes it finds between calls, so only the first call for a given number of digits pays for finding them.

On 4 cores, `pPrimesRange("1", "999999")` takes about 0.5 s. Listing every divisor of a number like `1111111` (5.66 million divisors) takes about 12 s.

### Tests

`mvn test` runs 39 JUnit tests that compare the results with the original C program's output. GitHub Actions runs them on Java 11 and 21 for every pull request. See [`test/README.md`](test/README.md) for details.
