# a column that names every constructor and then a variable: the variable
# row is dead there, and neither lane emits an arm for it
import Base

law pick:
  for p: U32 & Bool & Bool
  U32

def pick(p):
  match p:
    case (n, True{}, True{}):
      U32.add(n, 1)
    case (n, False{}, True{}):
      U32.add(n, 2)
    case (n, x, False{}):
      U32.add(n, 3)

law sum:
  for fuel: Nat
  for p: U32 & Bool & Bool
  U32

def sum(fuel, p):
  match fuel:
    case 0n:
      pick(p)
    case 1n+f:
      U32.add(sum(f, p), 1)

law main.out:
  U32

def main.out():
  U32.add(U32.add(sum(1n, (10, True{}, True{})), sum(0n, (0, False{}, True{}))),
    U32.add(sum(0n, (0, True{}, False{})), sum(0n, (0, False{}, False{}))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|20
