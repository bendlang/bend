# audit: constructor targets cannot change datatype parameters -- a ctor
# row takes no result annotation at all.
# ported from bend3: params move to bend's angle group
type Dd<n: Nat, A: Type> is Data:
  Cc{} : Dd(n, @x: Type -> x)

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|4 | type Dd<n: Nat, A: Type> is Data:
#|5>|   Cc{} : Dd(n, @x: Type -> x)
#|6 |
#|exit 1
