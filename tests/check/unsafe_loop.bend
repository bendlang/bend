# @unsafe on the line above a def skips the descent check: a bare
# self-call passes, and the def stays callable (main never calls it,
# so the run terminates)
import Base

law loops:
  for n: Nat
  Nat

@unsafe
def loops(n):
  loops(n)

law main:
  U32

def main(): 7

#|7
