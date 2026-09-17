# over-used match, direct case tree: main over-uses x, so each call
# consumes its own copy; the catch-all binds the value whole
# ported from bend3: the share becomes a +let, the builder walks a Nat
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law val:
  for x: Nt
  U32

def val(x):
  match x:
    case Zr{}:
      0
    case Sc{p}:
      U32.add(1, val(p))

law pick:
  for x: Nt
  U32

def pick(x):
  match x:
    case Zr{}:
      100
    case w:
      val(w)

law nat:
  for n: Nat
  Nt

def nat(n):
  match n:
    case 0n:
      Zr{}
    case 1n+m:
      Sc{nat(m)}

law main.out:
  U32

def main.out():
  +x = {nat(5n) : Nt}
  U32.add(pick(x), pick(x))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
