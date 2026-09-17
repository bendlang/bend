# The library's total-division convention at b = 0 (AUDIT 21): div
# answers 0, mod the DIVIDEND, so a = b * div(a,b) + mod(a,b) holds at
# every b. The base defs are the binary long division; the u32_div and
# u32_mod natives (runtime.c, runtime.js) answer the same rule, so all
# four lanes agree.
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law main.out:
  Nat

def main.out():
  b0 = bu(U32.is_eq(U32.div(7, 0), 0))
  b1 = bu(U32.is_eq(U32.mod(7, 0), 7))
  b2 = bu(U32.is_eq(U32.mod(4294967295, 0), 4294967295))
  b3 = bu(U32.is_eq(U32.mod(0, 0), 0))
  b4 = bu(U32.is_eq(U32.div(4294967295, 0), 0))
  b5 = bu(U32.is_eq(U32.div(0, 0), 0))
  U32.to_nat(U32.add(U32.add(U32.add(b0, b1), U32.add(b2, b3)), U32.add(b4, b5)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
