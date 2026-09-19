# THE ORDER BAN, nested: the ban is uniform at every nesting level --
# the same out-of-order match inside a constructor arm's field spine
# errors exactly like it does at a def's top level.
# ported from bend3
type Ny2 is Data:
  Zy2{}
  Sy2{p: Ny2}

type Py2 is Data:
  Pp2{a: Ny2, b: Ny2}

law f:
  for p: Py2
  Ny2

def f(p):
  match p:
    case Pp2{a, b}:
      match b, a:
        case Zy2{}, y:
          y
        case Sy2{k}, y:
          k

law main:
  Ny2

def main():
  Zy2{}

#|Error:
#|- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)
#|Location:
#|18 |     case Pp2{a, b}:
#|19>|       match b, a:
#|20 |         case Zy2{}, y:
#|exit 1
