# bend3's width-16 left-nested chain guarded the checker's exponential
# Op2 arm by interaction count; bend has no --stats, so the guard
# keeps its half that still speaks: the chain checks and answers on
# every lane through the infix ladder
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
  for x8: U32
  for x9: U32
  for xa: U32
  for xb: U32
  for xc: U32
  for xd: U32
  for xe: U32
  for xf: U32
  U32

def f(x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, xa, xb, xc, xd, xe, xf):
  (x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + xa + xb + xc + xd + xe + xf : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(f(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|120n
