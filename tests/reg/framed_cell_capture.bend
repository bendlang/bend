# regression (AUDIT 2b), repurposed: the framed match syntax is gone
# (a framed match was a lambda-match application in disguise), so the
# old cell spelling no longer parses -- pinned loud, not a silent
# capture-past-the-cell miscompile
import Base

law a:
  Bool

def a():
  False{}

law frame:
  for b: Bool
  Bool

def frame(b):
  match a : Bool = b, c : Bool = a:
    case x, y:
      y
  return Bool

law main:
  Bool

def main():
  frame(True{})

#|Error:
#|- message  : match scrutinees in binder order (this variable is unbound, consumed, or out of order: reorder the match)
#|Location:
#|17 | def frame(b):
#|18>|   match a : Bool = b, c : Bool = a:
#|19 |     case x, y:
#|exit 1
