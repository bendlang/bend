# the entry defines Exists as an empty type, so an imported law's where
# binder would range over nothing and an empty match would prove it. The
# where clause means the module's own Exists, so the match is refused
# (#1331: it used to certify)
import ./where_own_exists_lib.bend as L

type Vd is Data:

def Exists(-A: Type, -B: @-x: A -> Type) -> Type:
  Vd

def L.holds_when_gx(w):
  match w:

#|SOME PROOFS FAIL
#|Error:
#|- message  : this match doesn't cover where_own_exists_lib.Tup
#|Location: L.holds_when_gx
#|12 | def L.holds_when_gx(w):
#|13>|   match w:
#|   |   ^^^^^^^^
#|14 | 
#|Note: add the missing cases, or a catch-all case.
#|exit 1
