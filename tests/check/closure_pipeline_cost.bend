# bend3's gen_church miniature: an open-closure compose chain under
# binders. Its checker counter is gone (no --stats); the pipeline
# itself carries whole and answers on every lane
import Base

law comp:
  for f: U32 -> U32
  for g: U32 -> U32
  U32 -> U32

def comp(f, g):
  x => f(g(x))

law c0:
  for k: U32
  U32 -> U32

def c0(k):
  comp(x => (x + 0 : U32), x => (x + k : U32))

law c1:
  for k: U32
  U32 -> U32

def c1(k):
  comp(x => (x + 1 : U32), c0(k))

law c2:
  for k: U32
  U32 -> U32

def c2(k):
  comp(x => (x + 2 : U32), c1(k))

law c3:
  for k: U32
  U32 -> U32

def c3(k):
  comp(x => (x + 3 : U32), c2(k))

law ap:
  for f: U32 -> U32
  for x: U32
  U32

def ap(f, x):
  f(x)

law main.out:
  Nat

def main.out():
  U32.to_nat(ap(c3(4), 10))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|20n
