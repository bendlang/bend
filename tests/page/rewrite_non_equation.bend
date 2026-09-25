# error census: rewriting by a non-equation premise names the
# equation form
import Base
law f:
  for e: U32
  U32

def f(e):
  %e : U32
  3

#|Error:
#|- expected : an equation {a == b : T}
#|- observed : U32
#|Context:
#|- e : U32
#|Location: f
#| 8 | def f(e):
#| 9>|   %e : U32
#|   |    ^
#|10 |   3
#|exit 1
