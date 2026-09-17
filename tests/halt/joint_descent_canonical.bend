# THE JOINT-DESCENT GUARD: structural recursion THROUGH a fused joint
# match passes the descent judgment -- the multi-column match keeps
# (m, t) visible, and take(m, t) shrinks column 0.
# ported from bend3: U32 count becomes Nat (take's m - 1 rides the
# 1n+ pattern), bare ctors Cs/Nl, len answers Nat
import Base

type Lst is Data:
  Cs{h: U32, t: Lst}
  Nl{}

law take:
  for n  : Nat
  for xs : Lst
  Lst

def take(n, xs):
  match n, xs:
    case 0n, ys:
      Nl{}
    case 1n+m, Cs{h, t}:
      Cs{h, take(m, t)}
    case 1n+m, Nl{}:
      Nl{}

law len:
  for xs: Lst
  Nat

def len(xs):
  match xs:
    case Nl{}:
      0n
    case Cs{h, t}:
      1n+ len(t)

law main.out:
  Nat

def main.out():
  len(take(2n, Cs{7, Cs{8, Cs{9, Nl{}}}}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|2n
