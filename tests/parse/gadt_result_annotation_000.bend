# audit: native datatypes are parametric, not indexed by constructor
# targets -- a ctor row takes no result annotation.
# ported from bend3: parens params become angles
type Ix<n: Nat> is Data:
  I0{} : Ix(0n)

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|4 | type Ix<n: Nat> is Data:
#|5>|   I0{} : Ix(0n)
#|  |        ^
#|6 |
#|exit 1
