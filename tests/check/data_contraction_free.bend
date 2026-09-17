# audit 002 inverted, carried: bend3's Lone binder of Data type could be
# spent at any live quantity through the planted deep copy. bend spells
# the same clone as twin's +x binder (N is Data), and the block proves the clone semantics end-to-end:
# both copies of the tree are consumed independently.
# ported from bend3: the numeric nat(n) match becomes U32.to_nat + Nat
# recursion; ctor names bare and unique (Nat -> N, Pair -> Pr5)
import Base

type N is Data:
  Z{}
  S{p: N}
type Pr5 is Data:
  MkPr5{a: N, b: N}

law twin:
  for +x: N
  Pr5

def twin(x):
  MkPr5{x, x}

law nat.go:
  for m: Nat
  N

def nat.go(m):
  match m:
    case Zero{}:
      Z{}
    case Succ{q}:
      S{nat.go(q)}

law nat:
  for k: U32
  N

def nat(k):
  nat.go(U32.to_nat(k))

law val:
  for x: N
  U32

def val(x):
  match x:
    case Z{}:
      0
    case S{p}:
      (1 + val(p) : U32)

law main.sum:
  for q: Pr5
  U32

def main.sum(q):
  match q:
    case MkPr5{a, b}:
      (val(a) + val(b) : U32)

law main.out:
  U32

def main.out():
  main.sum(twin(nat(21)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
