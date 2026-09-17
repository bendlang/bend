# a bang over a closure-free record while a host closure sits next to
# it: the device holds the bang's target alone (once and its lambda
# stay on the host), and the value is the plain call's
import Base

type Pt is Type:
  Pt{x: U32, y: U32}

law norm1:
  for p: Pt
  U32

def norm1(p):
  match p:
    case Pt{x, y}:
      U32.add(x, y)

law once:
  for f: U32 -> U32
  for x: U32
  U32

def once(f, x):
  f(x)

law main.out:
  Nat

def main.out():
  h = once(z => U32.add(z, 1), 0)
  U32.to_nat(norm1!(Pt{h, 3}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|4n
