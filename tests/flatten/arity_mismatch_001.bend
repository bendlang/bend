# a case narrower than its match is rejected at parse time too.
# ported from bend3
type Nw2 is Data:
  Zw2{}
  Sw2{p: Nw2}

type Rw2 is Data:
  Aw2{}

law f:
  for a: Nw2
  for b: Nw2
  Rw2

def f(a, b):
  match a, b:
    case Zw2{}:
      Aw2{}

law main:
  Rw2

def main(): f(Zw2{}, Zw2{})

#|Error:
#|- expected : 2 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|16 |   match a, b:
#|17>|     case Zw2{}:
#|18 |       Aw2{}
#|exit 1
