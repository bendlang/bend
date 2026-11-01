# a live call to a def written below its caller: the error names the
# ordering rule, not the unfilled-law message (#1782)
import Base

def a(x: Nat) -> Nat:
  b(x)

def b(x: Nat) -> Nat:
  1n+x

def main() -> Nat:
  a(1n)

#|SOME PROOFS FAIL
#|Error:
#|- expected : a def written above a (move b above its first caller)
#|- observed : b
#|Context:
#|- x : Nat
#|Location: a
#|5 | def a(x: Nat) -> Nat:
#|6>|   b(x)
#|  |   ^
#|7 | 
#|exit 1
