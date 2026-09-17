# application binds through a space on one line: `id (True{})` is a
# call with head `id`. A newline ends the call spine.
# ported from bend3: bend3 ratified space-application; bend now
# agrees, so the port is the acceptance
import Base

law id:
  for x: Bool
  Bool

def id(x): x

law main:
  Bool

def main(): id (True{})

#|True{}
