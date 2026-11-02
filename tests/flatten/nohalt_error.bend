# a non-decreasing recursive call is rejected: descent needs some live
# argument to shrink (the rebuilt argument does not).
# ported from bend3
type Bx4 is Data:
  Tx4{}
  Fx4{}

law flip:
  for a: Bx4
  Bx4

def flip(a):
  match a:
    case Tx4{}:
      Fx4{}
    case Fx4{}:
      Tx4{}

law bad:
  for b: Bx4
  Bx4

def bad(b):
  match b:
    case Tx4{}:
      bad(flip(Tx4{}))
    case Fx4{}:
      Fx4{}

law main:
  Bx4

def main(): Fx4{}

#|SOME PROOFS FAIL
#|Error:
#|- expected : a call smaller than bad(Tx4{}) (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : bad(flip(Tx4{}))
#|Location: bad
#|25 |     case Tx4{}:
#|26>|       bad(flip(Tx4{}))
#|   |       ^^^
#|27 |     case Fx4{}:
#|exit 1
