# computed match on an operator expression: the decision moves to a
# worker def matching a Bool parameter, and the comparison rides in
# the call's argument position (an applied match-lambda is banned)
# ported from bend3: the arm reuses of a and b go affine (result params)
import Base

law main:
  for p: U32
  for q: U32
  for z: Bool
  U32

def main(p, q, z):
  match z:
    case False{}:
      p
    case True{}:
      q

#|p => q => \{False: p; True: q}
