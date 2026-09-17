# bend3's C-name dedup grew suffixes past a_k_x_ collisions minted by
# qualified names; bend ctor names are bare and globally unique, so
# the colliding trio spells as three distinct bare ctors and the
# emitter needs no dedup: the program answers on every lane
import Base

type A6 is Data:
  K_X_{v: U32}
  K_X{w: U32}
  X6{u: U32}

law f:
  for x: A6
  U32

def f(x):
  match x:
    case K_X_{v}:
      v
    case K_X{w}:
      (w + 10 : U32)
    case X6{u}:
      (u + 20 : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat((f(K_X_{1}) + f(K_X{2}) + f(X6{3}) : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|36n
