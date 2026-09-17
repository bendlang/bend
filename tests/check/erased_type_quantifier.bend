# an assert may quantify over Type with an ERASED for-all (-A); the
# unannotated fill binds it erased, the instantiation still applies the
# type argument explicitly.
# ported from bend3
import Base

law idT:
  for -A: Type
  for  x: A
  A

def idT(A, x):
  x

law main:
  U32

def main(): idT(U32, 9)

#|9
