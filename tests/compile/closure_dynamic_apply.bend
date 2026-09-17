# two-arg dynamic application + closure picked by a branch
# ported from bend3: the U32 branch becomes a Bool match
import Base

law pick:
  for n: Bool
  U32 -> U32 -> U32

def pick(n):
  match n:
    case True{}:
      a => b => U32.add(a, b)
    case False{}:
      a => b => U32.mul(a, b)

law use:
  (U32 -> U32 -> U32) -> U32

def use():
  f => f(3, 4)

law main.out:
  U32

def main.out():
  U32.add(use(pick(True{})), use(pick(False{})))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|19
