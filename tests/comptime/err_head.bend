# ~ under a plain def head (or a constructor or a local): only a
# template head reads ~ arguments, so elsewhere ~ heads no term
import Base

def main() -> Nat:
  Nat.add(~1n, 2n)

#|Error:
#|- expected : a term
#|- observed : '~'
#|Location:
#|5 | def main() -> Nat:
#|6>|   Nat.add(~1n, 2n)
#|7 |
#|exit 1
