# bend3's {a != b} desugar minted an Empty.Not def, so a user def of
# that name collided; bend's != unfolds structurally at parse time --
# no mint, no collision: a user Empty.Not coexists with the sugar
import Base

law Empty.Not:
  for -A: Type
  Type

def Empty.Not(A):
  A -> Empty

law NEQ:
  Type

def NEQ():
  {1n != 2n : Nat}

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(3n))

#|3
