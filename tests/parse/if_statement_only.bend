# bend3 confined if to statement position; bend removes the if term
# entirely (it desugared to a lambda-match application, a banned
# form). a match applied in term position is the checker's refusal,
# pinned here
import Base

law main.out:
  Nat

def main.out():
  \{True: 1n; False: 0n}({True{} : Bool})

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(main.out()))

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{True: 1n; False: 0n}
#|Location: main.out
#|10 | def main.out():
#|11>|   \{True: 1n; False: 0n}({True{} : Bool})
#|   |   ^^^^^^^^^^^^^^^^^^^^^^
#|12 |
#|exit 1
