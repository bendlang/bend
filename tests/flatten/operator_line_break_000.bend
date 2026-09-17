# an operator never heads a continuation line: a multi-line expression
# breaks AFTER the operator
# ported from bend3: doubled operands and word literals become params
# (bend's core is affine; a U32 literal shows as its Word chain)
import Base

law f:
  for a: U32
  for b: U32
  for c: U32
  U32

def f(a, b, c):
  x = (a + b : U32)
  s = x
  (s + c : U32)

law main:
  for a: U32
  for b: U32
  for c: U32
  for d: U32
  U32

def main(a, b, c, d):
  x = ((a +
    b : U32) +
    c : U32)
  s = x
  (s * d : U32)

#|a => b => c => d => U32.mul(U32.add(U32.add(a, b), c), d)
