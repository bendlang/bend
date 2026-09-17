# a param named after a top-level def SHADOWS it inside its body (a
# bound Var, never the Ref), while call sites outside still reach the
# def.
# ported from bend3: the shadowing body stays affine (one use)
import Base

law f:
  for x: U32
  U32

def f(x):
  U32.add(x, 1)

law g:
  for f: U32
  U32

def g(f):
  f

law main:
  U32

def main(): g(f(3))

#|4
