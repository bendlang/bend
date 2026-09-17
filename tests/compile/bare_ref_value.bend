# bare Ref value: a zero-arg def used as a value argument
# ported from bend3 (x * 2 -> U32.mul)
import Base

law seed:
  U32

def seed():
  42

law double:
  U32 -> U32

def double():
  x => U32.mul(x, 2)

law main.out:
  U32

def main.out():
  double(seed)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|84
