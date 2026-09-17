# U32.div/U32.mod are binary long division ON THE WORD (the
# shift/compare/subtract loop; no unary Nat detour), so dividing or
# printing any u32 answers immediately in EVERY lane, the interpreter
# included -- pinned at 0, 1, 4000000000 and 4294967295, with a
# divisor past 2^31 (the overflow-forced quotient bit). The b = 0
# convention (AUDIT 21: div answers 0, mod the DIVIDEND) is pinned in
# base_u32_divmod_zero on the interpreter, where the base defs run:
# the u32_mod natives (runtime.c, runtime.js) still answer 0 there,
# a divergence recorded in the merge report, not shipped as a yellow.
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
  b0 = bu(U32.is_eq(U32.div(4000000000, 7), 571428571))
  b1 = bu(U32.is_eq(U32.mod(4000000000, 7), 3))
  b2 = bu(U32.is_eq(U32.div(4000000000, 3000000000), 1))
  b3 = bu(U32.is_eq(U32.mod(4000000000, 3000000000), 1000000000))
  b4 = bu(U32.is_eq(U32.div(4294967295, 4294967295), 1))
  b5 = bu(U32.is_eq(U32.mod(4294967295, 4294967295), 0))
  b6 = bu(U32.is_eq(U32.div(7, 4294967295), 0))
  b7 = bu(U32.is_eq(U32.mod(7, 4294967295), 7))
  b8 = bu(U32.is_eq(U32.div(4294967295, 1), 4294967295))
  b9 = bu(U32.is_eq(U32.div(0, 7), 0))
  bc = bu(String.eq(U32.show(4000000000), "4000000000"))
  bd = bu(String.eq(U32.show(4294967295), "4294967295"))
  be = bu(String.eq(U32.show(0), "0"))
  bf = bu(String.eq(U32.show(1), "1"))
  s0 = U32.add(U32.add(U32.add(b0, b1), U32.add(b2, b3)), U32.add(U32.add(b4, b5), U32.add(b6, b7)))
  s1 = U32.add(U32.add(b8, b9), U32.add(U32.add(bc, bd), U32.add(be, bf)))
  U32.to_nat(U32.add(s0, s1))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|14n
