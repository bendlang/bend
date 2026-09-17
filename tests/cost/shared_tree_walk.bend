# bend3's two-walks-plus-one-copy guard loses its counter (no --stats)
# and keeps its value: the tree is consumed by two whole walks, spelled
# with a +T5 binder (T5 is Data, so the tree duplicates; bend3's
# over-use planted a copy), gen rides a Nat depth
import Base

type T5 is Data:
  Lf5{v: U32}
  Nd5{a: T5, b: T5}

law gen:
  for +d: Nat
  for +i: U32
  T5

def gen(d, i):
  match d:
    case Zero{}:
      Lf5{i}
    case Succ{k}:
      Nd5{gen(k, (i * 2 : U32)), gen(k, (i * 2 + 1 : U32))}

law tsum:
  for t: T5
  U32

def tsum(t):
  match t:
    case Lf5{v}:
      v
    case Nd5{a, b}:
      (tsum(a) + tsum(b) : U32)

law twice:
  for +t: T5
  U32

def twice(t):
  (tsum(t) + tsum(t) : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(twice(gen(4n, 1)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|752n
