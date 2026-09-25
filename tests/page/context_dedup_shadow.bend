import Base
# context dedup drops display-identical rows only: a REAL shadow keeps
# both rows -- the field's x is the OUTER N-typed binder, and a
# name-keyed dedup would show one x alone, a wrong type for the exact
# variable the page is about (bend spells the inner goal x as x^0)
type N is Data:
  NZ{}
  NS{p: N}

law f:
  for x: N
  (U32 -> {x == NS{x} : N})

def f(x):
  x => {==}

#|Error:
#|- expected : x^0
#|- observed : NS{x^0}
#|Context:
#|- x : N
#|- x : U32
#|Location: f
#|14 | def f(x):
#|15>|   x => {==}
#|   |        ^^^^
#|16 |
#|exit 1
