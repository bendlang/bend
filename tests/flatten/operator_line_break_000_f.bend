# an operator never heads a continuation line: a multi-line expression
# breaks AFTER the operator
# ported from bend3: doubled operands and word literals become params
# (bend's core is affine; a U32 literal shows as its Word chain)
import Base

law main:
  for a: U32
  for b: U32
  for c: U32
  U32

def main(a, b, c):
  x = (a + b : U32)
  s = x
  (s + c : U32)

#|a => b => c => U32.add(U32.add(a, b), c)
