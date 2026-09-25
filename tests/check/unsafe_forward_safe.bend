# an @unsafe def calls a def declared after it; a safe def after it may
# not: to live code, a def below is a bodiless claim, as an unfilled law
import Base

@unsafe
def f(x: Nat) -> Nat:
  g(x)

def h(x: Nat) -> Nat:
  g(x)

def g(x: Nat) -> Nat:
  x

def main() -> Nat:
  h(1n)

#|Error:
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : g
#|Context:
#|- x : Nat
#|Location: h
#| 9 | def h(x: Nat) -> Nat:
#|10>|   g(x)
#|   |   ^
#|11 |
#|exit 1
