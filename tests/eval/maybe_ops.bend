# base Maybe: pure/map compute through, None serves the default.
# ported from bend3: Maybe.some/none become Some/None, Maybe.or becomes
# Maybe.default (bend's arg order: a, A, m, d), map becomes a local def
# (bend base has none); result 507 (bend3's golden) shown as a Nat
import Base

law mmap:
  for f: @x:U32 -> U32
  for m: Maybe<&2, U32>
  Maybe<&2, U32>

def mmap(f, m):
  match m:
    case None{}:
      None{}
    case Some{value}:
      Some{f(value)}

law main.out:
  Nat

def main.out():
  U32.to_nat(U32.add(U32.mul(Maybe.default(&2, U32, mmap(x => U32.add(x, 1), Maybe.pure(&2, U32, 4)), 9), 100), Maybe.default(&2, U32, None{}, 7)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|507n
