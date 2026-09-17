# free word contraction feeding a recursive tail call: the element is
# both passed on and stored in the ctor
# ported from bend3: the counter walks a Nat, the doubled word a +param
import Base

type Lst is Data:
  Cn{h: U32, t: Lst}
  Nl{}

law go:
  for +f  : Nat
  for +n  : U32
  for acc : Lst
  Lst

def go(f, n, acc):
  match f:
    case 0n:
      acc
    case 1n+g:
      go(g, n, Cn{n, acc})

law main.go:
  for l: Lst
  U32

def main.go(l):
  match l:
    case Cn{h, t}:
      h
    case Nl{}:
      0

law main.out:
  U32

def main.out():
  main.go(go(3n, 242, Nl{}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|242
