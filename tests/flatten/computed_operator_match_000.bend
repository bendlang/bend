# computed match on an operator expression: the decision moves to a
# worker def matching a Bool parameter, and the comparison rides in
# the call's argument position (an applied match-lambda is banned)
# ported from bend3: the arm reuses of a and b go affine (result params)
import Base

law pick:
  for p: U32
  for q: U32
  for z: Bool
  U32

def pick(p, q, z):
  match z:
    case False{}:
      p
    case True{}:
      q

law main:
  for a: U32
  for b: U32
  for p: U32
  for q: U32
  U32

def main(a, b, p, q):
  pick(p, q, (a <= b : U32))

#|a => b => p => q => pick(p, q, Cmp.is_le(U32.cmp(a, b)))
