# bend3's Data-kinded dup planted a deep copy BY VALUE: a call in the
# duplicated position (dbl(3)) ran once and its value copied. bend's
# copy is the Data-licensed + binder and is by value the same way:
# dup3's +x lands in MkPr4{x, x} and both copies read 6, so the
# flattened readback doubles; Pr3 is Data, so the + binder
# is licensed. dbl's own x + x re-spend rides +x: U32.
# ported from bend3: the @-a: Data polymorphic dup is monomorphized
# (no Data kind); the printed-pair golden becomes the flattened sum
import Base

type Pr3 is Data:
  MkPr3{x: U32, y: U32}
type Pr4 is Data:
  MkPr4{a: Pr3, b: Pr3}

law dbl:
  for +x: U32
  U32

def dbl(x):
  (x + x : U32)

law dup3:
  for +x: Pr3
  Pr4

def dup3(x):
  MkPr4{x, x}

law flat.go:
  for p: Pr3
  U32

def flat.go(p):
  match p:
    case MkPr3{x, y}:
      (10 * x + y : U32)

law flat:
  for q: Pr4
  U32

def flat(q):
  match q:
    case MkPr4{a, b}:
      (flat.go(a) + flat.go(b) : U32)

law main.out:
  U32

def main.out():
  flat(dup3(MkPr3{dbl(3), 4}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|128
