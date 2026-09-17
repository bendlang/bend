# a float literal stands as a pattern, exactly as a U32 literal does:
# both are one-field word constructors, so the interpreter matches on
# one; the compiled lanes refuse a structural view of a machine word
import Base

law f:
  for x: F32
  U32

def f(x):
  match x:
    case 1.5:
      1
    case y:
      0

law main:
  U32

def main():
  f(1.5)

#|1
