# A constructor whose type is shared (counted: here a list passed through
# Base's polymorphic List.reverse and kept across a loop's turns) built
# before the call that fills it (C lane): each store into a hole seals what
# it stores, the root's and a call's answer alike. A map, a map of a map,
# and two defs that fill each other's holes. Every size comes from the
# command line's length (1 in the harness), which no compiler sees.
import Base

def mkl(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      i <> mkl(p, (i + 1 : U32))

def inc2(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      (h * 3 + 1 : U32) <> inc2(t)

@unsafe
def odd2(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      (h + 1000 : U32) <> even2(t)

@unsafe
def even2(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      (h * 2 : U32) <> odd2(t)

def lsum(xs: List<&2, U32>, +a: U32) -> U32:
  match xs:
    case Nil{}:
      a
    case Con{+h, t}:
      lsum(t, (a * 31 + h : U32))

def twice(+xs: List<&2, U32>) -> U32:
  U32.xor(lsum(xs, 0), lsum(inc2(inc2(xs)), 1))

def rep(k: Nat, +xs: List<&2, U32>, +a: U32) -> U32:
  match k:
    case 0n:
      a
    case 1n+p:
      rep(p, xs, U32.xor((a * 3 : U32), lsum(odd2(inc2(List.reverse(&2, U32, xs))), 1)))

def rows(n: Nat, +i: U32) -> List<&2, List<&2, U32>>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      mkl(Nat.add(U32.to_nat((i % 50 : U32)), 900n), i) <> rows(p, (i + 7 : U32))

def all(xss: List<&2, List<&2, U32>>, +a: U32) -> U32:
  match xss:
    case Nil{}:
      a
    case Con{xs, t}:
      all(t, U32.xor((a * 3 : U32), rep(3n, xs, 0)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(U32.show(all(rows(Nat.mul(20n, List.length(&1, String, args)), 3), 0)))
#| 1503167218
