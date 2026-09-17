# red-team pin: a statement's RHS expression breaks AFTER an operator
# (`x = s .&.` then the next line's operand).
# ported from bend3: doubled operand and word literal become params
import Base

law main:
  for a: U32
  for m: U32
  for w: U32
  U32

def main(a, m, w):
  s = a
  x = (s .&.
    m : U32)
  (x + w : U32)

#|a => m => w => U32.add(U32.and(a, m), w)
