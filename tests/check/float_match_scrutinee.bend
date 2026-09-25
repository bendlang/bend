# an F32 is a machine word wearing one constructor, like a U32, so a
# Chr arm on an F32 scrutinee is refused: Chr is no constructor of F32
# (a bare var arm is just a binder) -- parse_float_pattern holds the
# literal half
import Base

law f:
  for x: F32
  U32

def f(x):
  match x:
    case Chr{c}:
      0

law main:
  U32

def main():
  f(1.5)

#|Error:
#|- expected : a constructor of F32 (missing, or already matched)
#|- observed : \{Chr: (c => 0)}
#|Location: f
#|12 |   match x:
#|13>|     case Chr{c}:
#|   |          ^^^^^^
#|14 |       0
#|exit 1
