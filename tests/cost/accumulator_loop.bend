# bend3's interp cost guard (492 interactions at depth 24) loses its
# counter -- bend has no --stats -- and keeps its value: the
# accumulator loop rides a Nat countdown with a U32 mirror (the 1+n
# arm re-used the pred, which affine bend spells as two arguments)
import Base

law spin:
  for n   : Nat
  for +i  : U32
  for acc : U32
  U32

def spin(n, i, acc):
  match n:
    case Zero{}:
      acc
    case Succ{k}:
      spin(k, (i - 1 : U32), (acc + i : U32))

law main.out:
  Nat

def main.out():
  U32.to_nat(spin(24n, 24, 0))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|300n
