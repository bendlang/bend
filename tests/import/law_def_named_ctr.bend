# a law names its module's own def even when the def is declared below
# it and named like a Base constructor (Done): the def and the
# constructor live in separate tables. once the law resolved Done to
# the bare name, so an importer's own def Done restated the law, and a
# false proof checked (#1236)
import Base
import ./law_def_named_ctr_lib.bend as L

def Done(b: Bool) -> Bool:
  True{}

def L.thm(b):
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : b
#|- observed : True{}
#|Context:
#|- b : Bool
#|Location: L.thm
#|12 | def L.thm(b):
#|13>|   {==}
#|   |   ^^^^
#|14 |
#|Note: the left side of the equality is the expected, the right side is the observed.
#|exit 1
