# bend3's width-8 left-nested chain pinned the Op2 infer arm
# near-linear by interaction count; bend has no --stats, so the value
# half carries: the chain checks and answers on every lane
import Base

law f:
  for x0: U32
  for x1: U32
  for x2: U32
  for x3: U32
  for x4: U32
  for x5: U32
  for x6: U32
  for x7: U32
  U32

def f(x0, x1, x2, x3, x4, x5, x6, x7):
  (x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7 : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(f(0, 1, 2, 3, 4, 5, 6, 7))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|28n
