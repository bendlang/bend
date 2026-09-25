# regression (AUDIT 4a), repurposed: an erased local that is then
# matched is refused -- body_flatten once beta-contracted the binder
# into a bare application, so the None quantity never reached the
# checker. the local-then-match body is a banned form now, so the
# refusal comes from the flatten, before any quantity is measured
import Base

law leak:
  for z: Bool
  Bool

def leak(z):
  -x = {z : Bool}
  match x:
    case True{}:
      True{}
    case False{}:
      False{}

law main:
  Bool

def main():
  True{}

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
#|Location:
#|12 | def leak(z):
#|13>|   -x = {z : Bool}
#|   |   ^^
#|14 |   match x:
#|exit 1
