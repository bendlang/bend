# bend3's interp cost guard for a linear 16-cons fold loses its counter
# (no --stats in bend) and keeps its value: build's 1+n arm becomes a
# Nat countdown with a U32 mirror, fold carries over verbatim
import Base

type L is Data:
  LC{h: U32, t: L}
  LN{}

law build:
  for  n: Nat
  for +i: U32
  L

def build(n, i):
  match n:
    case Zero{}:
      LN{}
    case Succ{k}:
      LC{i, build(k, (i - 1 : U32))}

law fold:
  for xs  : L
  for acc : U32
  U32

def fold(xs, acc):
  match xs:
    case LN{}:
      acc
    case LC{h, t}:
      fold(t, (acc + h : U32))

law main.out:
  Nat

def main.out():
  U32.to_nat(fold(build(16n, 16), 0))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|136n
