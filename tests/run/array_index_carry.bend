# bounds carried through a match that takes successors off a word, a
# subtraction, a conversion and a helper: each in range and out of it
import Base

def zero(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

def v(+k: U32) -> U32:
  (k + zero(Array.get(U32, [0 : U32*1n], 0)) : U32)

def nat(+k: U32) -> Nat:
  U32.to_nat(v(k))

# 2^32 - 1 + k
def big(+k: U32) -> Nat:
  Nat.add(U32.to_nat(v(4294967295)), U32.to_nat(v(k)))

def fold(n: Nat, +j: U32, acc: U32, r: Array<U32> & U32) -> U32:
  match n:
    case 0n:
      (a, x) = r
      (acc * 31 + x : U32)
    case 1n+p:
      (a, x) = r
      +q = (j + 1 : U32)
      fold(p, q, (acc * 31 + x : U32), a[q])

def sum(a: Array<U32>) -> U32:
  fold(nat(15), 0, 0, a[0])

# a Nat fixed for the loop, matched in it: the index is x - (m - 1)
def fix(+n: Nat, +m: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      match m:
        case 0n:
          a
        case 1n+p:
          fix(q, m, x, a[U32.sub(x, U32.from_nat(p))] <- (x + 7 : U32))

# the fixed Nat matched first, two successors off it: the index is m - 2 + x
def fix2(+m: Nat, +n: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match m:
    case 0n:
      a
    case 1n:
      a
    case 2n+p:
      match n:
        case 0n:
          a
        case 1n+q:
          fix2(m, q, x, a[U32.add(U32.from_nat(p), x)] <- (x + 9 : U32))

# the fixed Nat matched in a helper: the index is x - (w - 1)
def fixh.at(+w: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match w:
    case 0n:
      a
    case 1n+t:
      a[U32.sub(x, U32.from_nat(t))] <- (x + 11 : U32)

def fixh(+n: Nat, +m: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      fixh(q, m, x, fixh.at(m, x, a))

# the countdown matched in a helper: the index is j + (n - 1)
def cnth.at(+w: Nat, +j: U32, a: Array<U32>) -> Array<U32>:
  match w:
    case 0n:
      a
    case 1n+t:
      a[U32.add(j, U32.from_nat(t))] <- (j + 13 : U32)

def cnth(+n: Nat, +j: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      cnth(q, (j + 1 : U32), cnth.at(n, j, a))

# a countdown past 2^32 under a second one: the index is (n - 1) - 4294967290
def past(+k: Nat, +n: Nat, a: Array<U32>) -> Array<U32>:
  match k:
    case 0n:
      a
    case 1n+k2:
      match n:
        case 0n:
          a
        case 1n+p:
          past(k2, p, a[U32.from_nat(Nat.sub(p, U32.to_nat(4294967290)))] <- 17)

# a fixed Nat past 2^32: its predecessor has no bound
def pastf(+n: Nat, +m: Nat, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      match m:
        case 0n:
          a
        case 1n+p:
          pastf(q, m, a[U32.from_nat(Nat.sub(p, U32.to_nat(4294967290)))] <- 19)

# a countdown past 2^32 that a flag ends early: the counter's steps have no bound
def early(+n: Nat, go: Bool, +j: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      match go:
        case False{}:
          a
        case True{}:
          early(p, U32.is_lt(j, 5), (j + 1 : U32), a[U32.shrn(j, 1n)] <- (j + 21 : U32))

# a def of the file's own, named like a comparison: its result has no bound
def U32.is_far(+x: U32) -> U32:
  (x + 9 : U32)

def own(+n: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      own(q, x, a[U32.is_far(x)] <- (x + 23 : U32))

# under zero: the counter less a constant, and a fixed word less the countdown
def under(+n: Nat, +j: U32, +x: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      b = a[U32.sub(j, 3)] <- (j + 25 : U32)
      under(p, (j + 1 : U32), x, b[U32.sub(x, U32.from_nat(p))] <- (j + 27 : U32))

# a shift by the countdown's predecessor: the lower bound of the count is what bounds it
def shift(+n: Nat, +x: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      shift(p, x, a[U32.shrn(x, Nat.sub(U32.to_nat(4), p))] <- (x + 29 : U32))

def main() -> IO(Unit):
  do IO<Unit>:
    # x - (m - 1): 3, then 4 (one past the end), then under zero
    IO.print(U32.show(sum(fix(nat(2), nat(3), v(5), [0 : U32*4n]))))
    IO.print(U32.show(sum(fix(nat(2), nat(3), v(6), [0 : U32*4n]))))
    IO.print(U32.show(sum(fix(nat(2), nat(5), v(2), [0 : U32*4n]))))
    IO.print(U32.show(sum(fix(nat(2), big(3), v(2), [0 : U32*4n]))))
    # m - 2 + x: 3, then 4
    IO.print(U32.show(sum(fix2(nat(4), nat(2), v(1), [0 : U32*4n]))))
    IO.print(U32.show(sum(fix2(nat(5), nat(2), v(1), [0 : U32*4n]))))
    IO.print(U32.show(sum(fix2(big(4), nat(2), v(1), [0 : U32*4n]))))
    # in a helper
    IO.print(U32.show(sum(fixh(nat(2), nat(3), v(5), [0 : U32*4n]))))
    IO.print(U32.show(sum(fixh(nat(2), nat(3), v(6), [0 : U32*4n]))))
    IO.print(U32.show(sum(fixh(nat(2), nat(4), v(2), [0 : U32*4n]))))
    # j + (n - 1): to 3 and to 4, and to the last of 8
    IO.print(U32.show(sum(cnth(nat(4), v(0), [0 : U32*4n]))))
    IO.print(U32.show(sum(cnth(nat(4), v(1), [0 : U32*4n]))))
    IO.print(U32.show(sum(cnth(nat(8), v(0), [0 : U32*8n]))))
    IO.print(U32.show(sum(cnth(nat(4), v(0), [0 : U32*16n]))))
    # past 2^32: the index is 10, on 8 cells and on 16
    IO.print(U32.show(sum(past(nat(1), big(6), [0 : U32*8n]))))
    IO.print(U32.show(sum(past(nat(1), big(6), [0 : U32*16n]))))
    IO.print(U32.show(sum(past(nat(3), U32.to_nat(v(4294967294)), [0 : U32*8n]))))
    IO.print(U32.show(sum(pastf(nat(2), big(6), [0 : U32*8n]))))
    IO.print(U32.show(sum(pastf(nat(2), U32.to_nat(v(4294967294)), [0 : U32*8n]))))
    IO.print(U32.show(sum(early(big(6), True{}, v(0), [0 : U32*4n]))))
    IO.print(U32.show(sum(early(nat(6), True{}, v(0), [0 : U32*4n]))))
    # the file's own def
    IO.print(U32.show(sum(own(nat(2), v(3), [0 : U32*4n]))))
    IO.print(U32.show(sum(own(nat(2), v(3), [0 : U32*16n]))))
    # under zero
    IO.print(U32.show(sum(under(nat(4), v(3), v(4), [0 : U32*8n]))))
    IO.print(U32.show(sum(under(nat(4), v(1), v(4), [0 : U32*8n]))))
    IO.print(U32.show(sum(under(nat(4), v(3), v(1), [0 : U32*8n]))))
    # shifts
    IO.print(U32.show(sum(shift(nat(3), v(60), [0 : U32*8n]))))
    IO.print(U32.show(sum(shift(nat(5), v(60), [0 : U32*8n]))))
    IO.print(U32.show(sum(shift(nat(3), v(60), [0 : U32*16n]))))

#|570596400
#|518183500
#|2528948060
#|1087978532
#|475497000
#|728984792
#|1855505112
#|760795200
#|1668770876
#|2765629748
#|760795200
#|1668770876
#|2505616424
#|3895486480
#|482133534
#|486695567
#|1866187234
#|3823241882
#|3032824358
#|1025752480
#|1025752480
#|1036367000
#|774566
#|3241927554
#|1382098248
#|3103656326
#|2084439652
#|380721152
#|2002246283
