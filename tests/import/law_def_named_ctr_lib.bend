# a module's law names a def declared below it, and the def is named
# like Base's Done constructor. alone, the law is unfilled
import Base

law thm:
  for b: Bool
  {Done(b) == True{} : Bool}

def Done(b: Bool) -> Bool:
  b

#|SOME PROOFS FAIL
#|Error: 1 TODO found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
