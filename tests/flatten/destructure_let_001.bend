# bend3 pinned `P = e` as a statement AFTER a plain let; bend bans it:
# destructuring a local binder is a lambda-match application, so the
# flattener rejects and the destructure belongs in a worker def
import Base

type Duo is Data:
  P{a: U32, b: U32}

law main:
  for p: Duo
  U32

def main(p):
  q = p
  P{a, b} = q
  (a - b : U32)

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
#|Location:
#|13 | def main(p):
#|14>|   q = p
#|15 |   P{a, b} = q
#|exit 1
