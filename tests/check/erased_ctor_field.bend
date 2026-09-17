# erased constructor fields: `-A: Type` in a type declaration exists
# only at check time. Construction supplies the erased argument
# explicitly; an erased def param may legally feed it. Matching binds
# the erased field too, but it must stay unused.
# ported from bend3: def <A> params become an erased -A bind
import Base

type Bxb is Type:
  Mkb{-A: Type, v: A, tag: Nat}

law mk:
  for -A: Type
  for  x: A
  Bxb

def mk(A, x):
  Mkb{A, x, 7n}

law peek:
  for b: Bxb
  Nat

def peek(b):
  match b:
    case Mkb{A, v, tag}:
      tag

law main:
  Nat

def main(): peek(mk(Nat, 3n))

#|7n
