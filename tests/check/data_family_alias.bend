# bend3 pinned that a type family is Data HOWEVER it is spelled -- a def
# reference and a partial application classify like the literal lambda.
# the grade kernel reads the family's declared kind: CF and CF2 answer
# Data, so a reusable dependent pair Sigma<&2, &2, U32, a => CF(a)> is
# Data and the double reads ride +p, the family applied in the body
# (a bare-ref second component has no bend spelling), ref and partial
# application alike, because each unfolds to U32.
# ported from bend3: Pair(U32, CF) -> Sigma<&2, &2, U32, a => CF(a)>;
# Pair(U32, CF2(1n)) applies the family at its Nat leg, CF2(1n, a)
import Base

law CF:
  for x: U32
  Data

def CF(x):
  U32

law CF2:
  for a: Nat
  for x: U32
  Data

def CF2(a, x):
  U32

law ref_a:
  for p: Sigma<&2, &2, U32, a => CF(a)>
  U32

def ref_a(p):
  (a, b) = p
  a

law ref_b:
  for p: Sigma<&2, &2, U32, a => CF(a)>
  U32

def ref_b(p):
  (a, b) = p
  b

law by_ref:
  for +p: Sigma<&2, &2, U32, a => CF(a)>
  U32

def by_ref(p):
  (ref_a(p) + ref_b(p) : U32)

law part_a:
  for p: Sigma<&2, &2, U32, a => CF2(1n, a)>
  U32

def part_a(p):
  (a, b) = p
  a

law part_b:
  for p: Sigma<&2, &2, U32, a => CF2(1n, a)>
  U32

def part_b(p):
  (a, b) = p
  b

law by_part:
  for +p: Sigma<&2, &2, U32, a => CF2(1n, a)>
  U32

def by_part(p):
  (part_a(p) + part_b(p) : U32)

law main.out:
  U32

def main.out():
  (by_ref((1, 2)) * 10 + by_part((3, 4)) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|37
