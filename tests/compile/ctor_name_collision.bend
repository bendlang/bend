# bend3's 46->95 flattening collision (A_B.X vs A.B_X both reading
# A_B_X in C); bend has no qualified ctor names to flatten -- the
# bare names X_c and B_X are simply distinct, every site resolves by
# name, and both builds answer alike
import Base

type A_B6 is Data:
  X_c{v: U32}

type A6b is Data:
  B_X{v: U32}

law f:
  for x: A_B6
  for y: A6b
  U32

def f(x, y):
  match x:
    case X_c{v}:
      match y:
        case B_X{w}:
          (v + w : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(f(X_c{30}, B_X{12}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|42n
