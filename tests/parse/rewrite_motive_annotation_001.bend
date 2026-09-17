# bend3 refused the '_' motive in constructor discrimination; bend
# binds it, so the isZ transport CHECKS and 0n == 1n yields Empty --
# the inverted law at a dependent motive
import Base

law isZ2:
  for n: Nat
  Type

def isZ2(n):
  match n:
    case Zero{}:
      Unit
    case Succ{k}:
      Empty

law neq:
  for e: {0n == 1n : Nat}
  Empty

def neq(e):
  %e : isZ2(_)
  Unit{}

law main.out:
  U32

def main.out():
  0

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
