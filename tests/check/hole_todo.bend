# ?TODO is the quiet hole: it checks at any goal, but an unfinished
# proof is incomplete: the CLI refuses the file, main or not
import Base

law th:
  for n: Nat
  {Nat.add(n, 0n) == n : Nat}

def th(n):
  ?TODO

law main:
  U32

def main(): 7

#|Error: 1 TODO found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
