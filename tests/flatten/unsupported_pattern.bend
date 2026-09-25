# a lambda is not a pattern: the case head is refused with the pattern
# grammar (a binder or a constructor).
# ported from bend3
type Nu is Data:
  Zu{}
  Su{p: Nu}

type Ru is Data:
  Au{}

law f:
  for a: Nu
  Ru

def f(a):
  match a:
    case x => x:
      Au{}

law main:
  Ru

def main(): f(Zu{})

#|Error:
#|- expected : a pattern (a binder or a constructor)
#|- observed : x => x
#|Location:
#|16 |   match a:
#|17>|     case x => x:
#|   |          ^
#|18 |       Au{}
#|exit 1
