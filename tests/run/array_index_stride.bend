# loops whose counter steps by another word, or down, wrapping or in range
import Base

def zero(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

# k, unknown to the compiler
def v(+k: U32) -> U32:
  (k + zero(Array.get(U32, [0 : U32*1n], 0)) : U32)

def nat(+k: U32) -> Nat:
  U32.to_nat(v(k))

def fold(n: Nat, +j: U32, acc: U32, r: Array<U32> & U32) -> U32:
  match n:
    case 0n:
      (a, x) = r
      (acc * 31 + x : U32)
    case 1n+p:
      (a, x) = r
      +q = (j + 1 : U32)
      fold(p, q, (acc * 31 + x : U32), a[q])

def sum(+m: U32, a: Array<U32>) -> U32:
  fold(U32.to_nat((m - 1 : U32)), 0, 0, a[0])

def up.at(+j: U32, r: Array<U32> & U32) -> Array<U32>:
  (b, +x) = r
  b[j] <- (x + j + 1 : U32)

# a[j] <- a[j] + j + 1, for n cells from j, step apart
def up(+n: Nat, +j: U32, +step: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      up(p, (j + step : U32), step, up.at(j, a[j]))

# the same, the next index bound by a let
def upl(+n: Nat, +j: U32, +step: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      +q = (j + step : U32)
      upl(p, q, step, a[j] <- (j * 5 + 3 : U32))

# down by a constant: a[j] for j, j - 2, j - 4, ..
def dn(+n: Nat, +j: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      dn(p, (j - 2 : U32), a[j] <- (j * 7 + 1 : U32))

# down by a word
def dnw(+n: Nat, +j: U32, +s: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      dnw(p, (j - s : U32), s, a[j] <- (j * 9 + 2 : U32))

# the step changes as the loop runs: no bound
def grow(+n: Nat, +j: U32, +s: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      grow(p, (j + s : U32), (s + 1 : U32), a[j] <- (j + 11 : U32))

def sumc.y(acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +x) = r
  (a, (acc * 31 + x : U32))

def sumc.at(+j: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  (a, acc) = s
  sumc.y(acc, a[j])

# acc * 31 + a[j] for n cells from j, step apart: a loop that only reads
def sumc(+n: Nat, +j: U32, +step: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      s
    case 1n+p:
      sumc(p, (j + step : U32), step, sumc.at(j, s))

# the same, down by a word
def sumd(+n: Nat, +j: U32, +step: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      s
    case 1n+p:
      sumd(p, (j - step : U32), step, sumc.at(j, s))

# the same, the step growing by one each turn: no bound
def sumg(+n: Nat, +j: U32, +step: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      s
    case 1n+p:
      sumg(p, (j + step : U32), (step + 1 : U32), sumc.at(j, s))

def sumc.fin(r: Array<U32> & U32) -> U32:
  (a, +x) = r
  x

# a sum over a column, step apart, through a cycle of two defs
@unsafe
def col.at(+n: Nat, +j: U32, +step: U32, acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +x) = r
  col(n, (j + step : U32), step, (acc * 31 + x : U32), a)

@unsafe
def col(+n: Nat, +j: U32, +step: U32, acc: U32, a: Array<U32>) -> Array<U32> & U32:
  match n:
    case 0n:
      (a, acc)
    case 1n+p:
      col.at(p, j, step, acc, a[j])

def colsum.fin(r: Array<U32> & U32) -> U32:
  (b, +s) = r
  (s + sum(16, b) : U32)

def colsum(+n: Nat, +j: U32, +step: U32, a: Array<U32>) -> U32:
  colsum.fin(col(n, j, step, 0, a))

def main() -> IO(Unit):
  do IO<Unit>:
    # step 3 over 16 cells: to 15 (in range), to 18 (past the end)
    IO.print(U32.show(sum(16, up(nat(6), v(0), v(3), [0 : U32*16n]))))
    IO.print(U32.show(sum(16, up(nat(7), v(0), v(3), [0 : U32*16n]))))
    # step 0, and a step that wraps past 2^32
    IO.print(U32.show(sum(16, up(nat(20), v(5), v(0), [0 : U32*16n]))))
    IO.print(U32.show(sum(16, up(nat(20), v(1), v(2147483648), [0 : U32*16n]))))
    IO.print(U32.show(sum(16, up(nat(20), v(3), v(4294967295), [0 : U32*16n]))))
    # through a let: in range, past the end
    IO.print(U32.show(sum(32, upl(nat(17), v(0), v(1), [0 : U32*32n]))))
    IO.print(U32.show(sum(32, upl(nat(17), v(20), v(1), [0 : U32*32n]))))
    # down by 2 from 31 (in range), from 15 under zero
    IO.print(U32.show(sum(32, dn(nat(16), v(31), [0 : U32*32n]))))
    IO.print(U32.show(sum(32, dn(nat(17), v(15), [0 : U32*32n]))))
    IO.print(U32.show(sum(32, dn(nat(16), v(30), [0 : U32*32n]))))
    # down by a word: in range, under zero, by 0
    IO.print(U32.show(sum(32, dnw(nat(16), v(31), v(1), [0 : U32*32n]))))
    IO.print(U32.show(sum(32, dnw(nat(17), v(31), v(3), [0 : U32*32n]))))
    IO.print(U32.show(sum(32, dnw(nat(17), v(9), v(0), [0 : U32*32n]))))
    # a growing step: to 15, and past the end (its first step bounds nothing)
    IO.print(U32.show(sum(16, grow(nat(5), v(0), v(1), [0 : U32*16n]))))
    IO.print(U32.show(sum(32, grow(nat(17), v(0), v(1), [0 : U32*32n]))))
    # a read-only column, step 3 then 5 over 64 cells: in range, past the end, wrapping
    IO.print(U32.show(sumc.fin(sumc(nat(20), v(1), v(3), (upl(nat(64), v(0), v(1), [0 : U32*64n]), 0)))))
    IO.print(U32.show(sumc.fin(sumc(nat(20), v(1), v(5), (upl(nat(64), v(0), v(1), [0 : U32*64n]), 0)))))
    IO.print(U32.show(sumc.fin(sumc(nat(20), v(4294967290), v(1), (upl(nat(64), v(0), v(1), [0 : U32*64n]), 0)))))
    # read-only, down by 1 from 31 (in range) and by 3 from 31 (under zero), over 32 cells
    IO.print(U32.show(sumc.fin(sumd(nat(17), v(31), v(1), (upl(nat(32), v(0), v(1), [0 : U32*32n]), 0)))))
    IO.print(U32.show(sumc.fin(sumd(nat(17), v(31), v(3), (upl(nat(32), v(0), v(1), [0 : U32*32n]), 0)))))
    # read-only, a growing step from 1 over 32 cells: past the end
    IO.print(U32.show(sumc.fin(sumg(nat(17), v(0), v(1), (upl(nat(32), v(0), v(1), [0 : U32*32n]), 0)))))
    # a column through two defs: in range, past the end
    IO.print(U32.show(colsum(nat(16), v(1), v(1), upl(nat(16), v(0), v(1), [0 : U32*16n]))))
    IO.print(U32.show(colsum(nat(16), v(1), v(5), upl(nat(16), v(0), v(1), [0 : U32*16n]))))




#|1520716073
#|505036790
#|3409169016
#|172530216
#|2975967818
#|1269903989
#|523167761
#|255946512
#|3459467056
#|303297376
#|1617478216
#|3977019969
#|236236819
#|1332618953
#|2261874949
#|489379478
#|4235580858
#|1303532146
#|1387629942
#|1646206758
#|3537615627
#|3660892928
#|2623740672
