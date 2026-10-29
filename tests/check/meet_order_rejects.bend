# a meet fits a kind only when every one of its leaves does: q <&> r may
# be below q, so Kind(q <&> r) does not fit Kind(q). the search that
# stops at its first answer (#1942) stops at its first failing leaf too,
# and still refuses
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
#|5 | def drop(q: Quant, r: Quant, X: Kind(q <&> r)) -> Kind(q):
#|6>|   X
#|  |   ^
#|7 | 
#|exit 1
