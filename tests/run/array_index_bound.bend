# loops whose index wraps, or stays in range, in the shapes a bound must get right
import Base

# r is a[j]: n more reads follow it, at j + 1, j + 2, ..
def fold(n: Nat, +j: U32, acc: U32, r: Array<U32> & U32) -> U32:
  match n:
    case 0n:
      (a, x) = r
      (acc * 31 + x : U32)
    case 1n+p:
      (a, x) = r
      +q = (j + 1 : U32)
      fold(p, q, (acc * 31 + x : U32), a[q])

# a[j] <- j * 3 + 1 for n + 1 cells from j
def fill(n: Nat, +j: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a[j] <- (j * 3 + 1 : U32)
    case 1n+p:
      fill(p, (j + 1 : U32), a[j] <- (j * 3 + 1 : U32))

# down from the top: a[top - p]
def down(+n: Nat, +top: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      +i = U32.sub(top, U32.from_nat(p))
      down(p, top, a[i] <- (i + 7 : U32))

# a step of 3 and an offset: a[j * 3 + off]
def step(n: Nat, +j: U32, +off: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      step(p, (j + 1 : U32), off, a[(j * 3 + off : U32)] <- j)

# a clamped data index: a[min(x, k)], a[x & 7], a[x % m]
def clamp(n: Nat, +x: U32, +k: U32, +m: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      +y = (x * 1664525 + 1013904223 : U32)
      b = a[U32.min(y, k)] <- y
      c = b[(y .&. 7 : U32)] <- (y >> 3n : U32)
      clamp(p, y, k, m, c[(y % m : U32)] <- (y >> 5n : U32))

# the counter wraps past 2^32
def high(n: Nat, +j: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      high(p, (j + 1 : U32), a[j] <- j)

def sum(a: Array<U32>) -> U32:
  fold(15n, 0, 0, a[0])

def main() -> IO(Unit):
  do IO<Unit>:
    # in range
    IO.print(U32.show(sum(fill(15n, 0, [0 : U32*16n]))))
    # wraps twice around
    IO.print(U32.show(sum(fill(40n, 9, [0 : U32*16n]))))
    IO.print(U32.show(fold(40n, 13, 0, Array.get(U32, fill(15n, 0, [0 : U32*16n]), 13))))
    # down, in range and under zero
    IO.print(U32.show(sum(down(16n, 15, [0 : U32*16n]))))
    IO.print(U32.show(sum(down(16n, 9, [0 : U32*16n]))))
    IO.print(U32.show(sum(down(40n, 15, [0 : U32*16n]))))
    # steps
    IO.print(U32.show(sum(step(5n, 0, 1, [0 : U32*16n]))))
    IO.print(U32.show(sum(step(9n, 2, 5, [0 : U32*16n]))))
    # clamps: the bounds fit, then do not
    IO.print(U32.show(sum(clamp(50n, 1, 15, 16, [0 : U32*16n]))))
    IO.print(U32.show(sum(clamp(50n, 1, 40, 23, [0 : U32*16n]))))
    # a counter over 2^32
    IO.print(U32.show(sum(high(20n, 4294967290, [0 : U32*16n]))))

#|2111205656
#|1900042008
#|1222669796
#|2436126472
#|1962791176
#|2436126472
#|895032386
#|1389217158
#|3198183671
#|1385818678
#|3838340616
