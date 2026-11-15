# a law cannot type a template: the fill after a law takes bare names
import Base

law app:
  for f: Nat -> Nat
  for x: Nat
  Nat

def app(~f, x):
  f(x)

#|SOME PROOFS FAIL
#|Error:
#|- expected : bare parameter names and no '->' (def app fills a law, which gives the types)
#|- observed : '~'
#|Location:
#| 8 | 
#| 9>| def app(~f, x):
#|   |         ^
#|10 |   f(x)
#|exit 1
