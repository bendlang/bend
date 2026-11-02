# a meet fits only when every leaf on its left fits: q <&> r may be
# below q, so Kind(q <&> r) does not fit Kind(q)
def drop(q: Quant, r: Quant, X: Kind(q <&> r)) -> Kind(q):
  X

#|SOME PROOFS FAIL
#|Error:
#|- expected : Kind(q)
#|- observed : Kind(q <&> r)
#|Context:
#|- q : Quant
#|- r : Quant
#|- X : Kind(q <&> r)
#|Location: drop
#|3 | def drop(q: Quant, r: Quant, X: Kind(q <&> r)) -> Kind(q):
#|4>|   X
#|  |   ^
#|5 | 
#|exit 1
