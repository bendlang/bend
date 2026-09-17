# list literal sugar: [a,b,c] is Con/Nil, in terms and patterns --
# ported from bend3; literals sit in checked positions (bend infers
# no ctor), and the readback folds to one U32 (a List is not
# C-showable)
import Base

law rev:
  for xs  : List<&2, U32>
  for acc : List<&2, U32>
  List<&2, U32>

def rev(xs, acc):
  match xs:
    case h <> t:
      rev(t, h <> acc)
    case Nil{}:
      acc

law csum:
  for xs  : List<&2, U32>
  for acc : U32
  U32

def csum(xs, acc):
  match xs:
    case h <> t:
      csum(t, (10 * acc + h : U32))
    case Nil{}:
      acc

law main.out:
  U32

def main.out():
  csum(rev([1, (2 + 3 : U32), 3], [0]), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3510
