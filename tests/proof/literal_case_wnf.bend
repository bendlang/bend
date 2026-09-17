# chained literal cases prove by plain wnf, respelled on Nat's ladder
# (the ruled port of bend3's 0/1/2+p U32 switch): each arm of the
# constant function reduces on its own, so every proof arm is {==}
# with no rewrite and no elaborator help, and the U32 face carries the
# runtime.
# ported from bend3: main keeps the golden 7
import Base

law sevenn:
  for x: Nat
  Nat

def sevenn(x):
  match x:
    case 0n:
      7n
    case 1n:
      7n
    case 2n+p:
      7n

law seven_all:
  for x: Nat
  {sevenn(x) == 7n : Nat}

def seven_all(x):
  match x:
    case 0n:
      {==}
    case 1n:
      {==}
    case 2n+p:
      {==}

law sevenu:
  for x: U32
  U32

def sevenu(x):
  U32.from_nat(sevenn(U32.to_nat(x)))

law main.out:
  U32

def main.out():
  sevenu(3)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
