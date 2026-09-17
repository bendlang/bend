# Lone-element array of a boxed ctor: swap is the only op, old values
# move out whole
# ported from bend3: the 1-slot [:P] literal becomes a bare ALeaf
import Base

type Pr is Data:
  MkPr{a: U32, b: U32}
  Ep{}

law pairsum:
  for p: Pr
  U32

def pairsum(p):
  match p:
    case MkPr{a, b}:
      U32.add(a, b)
    case Ep{}:
      0

law swp.b:
  for old : Pr
  for r   : Array<Pr> & Pr
  U32

def swp.b(old, r):
  (a3, old2) = r
  U32.add(pairsum(old), pairsum(old2))

law swp.a:
  for r: Array<Pr> & Pr
  U32

def swp.a(r):
  (a2, old) = r
  swp.b(old, Array.swap(Pr, a2, 0, MkPr{1, 1}))

law swp:
  for a: Array<Pr>
  U32

def swp(a):
  swp.a(Array.swap(Pr, a, 0, MkPr{8, 9}))

law main.out:
  U32

def main.out():
  swp(ALeaf{MkPr{2, 3}})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|22
