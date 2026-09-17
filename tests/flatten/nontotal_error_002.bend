# NotTotal names the missing constructor of a partial match.
# ported from bend3
type Ne2 is Data:
  Ze2{}
  Se2{p: Ne2}

type Re2 is Data:
  Ae2{x: Ne2}
  Be2{x: Ne2}

law f:
  for a: Ne2
  Re2

def f(a):
  match a:
    case Se2{a}:
      Ae2{a}

law main:
  Re2

def main(): f(Se2{Ze2{}})

#|Error:
#|- expected : cases for Ze2
#|- observed : \{}
#|Location: f
#|15 | def f(a):
#|16>|   match a:
#|17 |     case Se2{a}:
#|exit 1
