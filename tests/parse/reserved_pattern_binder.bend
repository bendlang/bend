# audit: reserved words are rejected as pattern binders.
# ported from bend3
type Nn10 is Data:
  Zx{}
  Sx{p: Nn10}

law f:
  for n: Nn10
  Nn10

def f(n):
  match n:
    case Sx{return}:
      Zx{}
    case Zx{}:
      Zx{}

law main:
  Nn10

def main(): f(Zx{})

#|Error:
#|- expected : a do-block heading this return
#|- observed : 'return'
#|Location:
#|12 |   match n:
#|13>|     case Sx{return}:
#|   |             ^^^^^^
#|14 |       Zx{}
#|exit 1
