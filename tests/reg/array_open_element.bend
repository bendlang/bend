# regression witness (2ff58c0): an OPEN Array element type refuses loud
# at emission -- one untyped segment cannot serve two representations,
# so a generic helper over Array<T> is reported, never compiled wrong.
# The evaluator and the JS backend run it fine.
import Base

law gcount:
  for -T: Type
  for  a: Array<T>
  U32

def gcount(T, a):
  match a:
    case ALeaf{x}:
      d = x
      1
    case ANode{xs, ys}:
      U32.add(gcount(T, xs), gcount(T, ys))

law main.out:
  U32

def main.out():
  gcount(U32, ANode{ALeaf{3}, ALeaf{4}})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|Error: an open Array element type
#|exit 1
