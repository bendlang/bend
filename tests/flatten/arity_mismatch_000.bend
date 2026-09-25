# a case gives ONE pattern per scrutinee, and a wider case is rejected
# at parse time.
# ported from bend3
type Nw is Data:
  Zw{}
  Sw{p: Nw}

type Rw is Data:
  Aw{x: Nw}
  Bw{y: Nw, z: Nw}

law f:
  for a: Nw
  for b: Nw
  Rw

def f(a, b):
  match a, b:
    case Zw{}, x, Zw{}:
      Aw{x}
    case y, z:
      Bw{y, z}

law main:
  Rw

def main(): f(Zw{}, Zw{})

#|Error:
#|- expected : 2 patterns (one per scrutinee)
#|- observed : 'Zw{}, x, Zw{}'
#|Location:
#|18 |   match a, b:
#|19>|     case Zw{}, x, Zw{}:
#|   |          ^^^^^^^^^^^^^
#|20 |       Aw{x}
#|exit 1
