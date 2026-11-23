# lazy splits: second calls whose results are a list, a pair and a tree, and
# whose arguments share one array with the first call (read by both sides);
# the long side is first, so the second is split off and its result waited
# for. Checks every result and that nothing leaks.
import Base

type T is Data:
  L{x: U32}
  N{l: T, r: T}

def build(+d: Nat, +i: U32) -> T:
  match d:
    case 0n:
      L{i}
    case 1n+p:
      l r = build(p, (i * 2 : U32)) build(p, (i * 2 + 1 : U32))
      N{l, r}

def sum(t: T) -> U32:
  match t:
    case L{x}:
      x
    case N{l, r}:
      (sum(l) + sum(r) : U32)

def upto(+n: Nat, +i: U32) -> List<U32>:
  match n:
    case 0n:
      []
    case 1n+p:
      i <> upto(p, (i + 1 : U32))

def lsum(xs: List<U32>) -> U32:
  match xs:
    case []:
      0
    case h <> t:
      (h + lsum(t) : U32)

def pair(+i: U32) -> U32 & U32:
  ((i + 1 : U32), (i * 3 : U32))

def graft(+i: U32) -> T:
  N{build(6n, (i + 7 : U32)), build(11n, i)}

def cnt(+i: U32) -> List<U32>:
  i <> upto(3000n, i)

def fin(+q: U32, +l: U32, s: U32 & U32) -> U32:
  (+x, +y) = s
  (q + l + x + y : U32)

def one(+i: U32, t: T, xs: List<U32>) -> U32:
  q s = sum(t) pair(i)
  fin(q, lsum(xs), s)

def both(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      0
    case 1n+p:
      t xs = graft(i) cnt(i)
      (one(i, t, xs) + both(p, (i + 1 : U32)) : U32)

def main() -> U32:
  both(40n, 1)

#|3710164780
