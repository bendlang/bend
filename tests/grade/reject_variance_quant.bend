# a quantity whose type only evaluates to Quant still sets a kind: an
# affine Box<&1> is no reusable Box<&2>, though Box has no field
def Q() -> Type:
  Quant

type Box<-q: Q()> is Kind(q):
  Box{}

def strengthen(x: Box<&1>) -> Box<&2>:
  x

#|SOME PROOFS FAIL
#|Error:
#|- expected : Box<&2>
#|- observed : Box<&1>
#|Context:
#|- x : Box<&1>
#|Location: strengthen
#| 9 | def strengthen(x: Box<&1>) -> Box<&2>:
#|10>|   x
#|   |   ^
#|11 | 
#|exit 1
