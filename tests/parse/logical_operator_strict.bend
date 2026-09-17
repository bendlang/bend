# && and || are Bool operators desugaring to Bool.and/Bool.or -- both
# operands are values (strict, as bend3 pinned), and the operands are
# Bool, not words (no U32-Bool bridge in bend)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law main.out:
  U32

def main.out():
  a = bu(True{} && True{})
  b = bu(True{} && False{})
  c = bu(False{} || True{})
  d = bu(False{} || False{})
  (a + 10 * b + 100 * c + 1000 * d : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|101
