# a two-step ladder: even(3n+x) unfolds one full step to even(1n+x),
# then the outer match passes and the inner one sticks on x. The
# goal is even(1n+x): the unfolded step is taken (no under-reduction)
# and the stuck step is folded back (no exposed match).
import Base

law even:
  for n: Nat
  Bool

def even(n):
  match n:
    case 0n:
      True{}
    case 1n+p:
      match p:
        case 0n:
          False{}
        case 1n+q:
          even(q)

law main:
  @x:Nat -> Bool

def main():
  x => even(3n+x)

#|x => even(1n+x)
